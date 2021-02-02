---
layout: post
title:  "using Go and alpine linux to minimize docker image size"
date:   2021-02-03 00:00:00 +0300
categories: sysadmin
summary: Here I will show you how to use Go and alpine linux to minimize docker image size
---

# Introduction
Using docker for application developent and deployment became a standard in software development, everyone
must be able to use docker to developm their software, this will make it a lot easier to deploy software
in the future using container orchestration platforms such as kubernetes.

Creating a docker image for production is not an easy task, you need to make sure the image can be easily
configured at runtime to be used in different setups and also make sure the image is as small and compact
as possible, no need to put anything not needed in the image.

As an example we will create a docker image for ZooKeeper and then work to decrease its size to be more
suitable for production use.

# What will we do?

In this tutorial we will:

* Create a docker image for ZooKeeper
* Use python to setup the configuration file as needed.
* Use go and java alpine image to reduce size.
* Use Linux alpine from scratch to reduce size again.

# ZooKeeper in Docker
ZooKeeper is a centralized service for maintaining configuration information, naming, providing distributed
synchronization and group services. All of these services are needed for distributed applications to work
and coordinate together. ZooKeeper can be used to provide the mentioned services instead of implementing
a solution everytime we need to write a distributed application.

We already talked about docker and its importance, here we will use create a docker image to run ZooKeeper
in it, first we will start simple, calculate the image size and then work reduce this size as much as we can.

Here is the first Docker file that we will use to create the first image:

```
FROM openjdk:11
RUN wget https://ftp.halifax.rwth-aachen.de/apache/zookeeper/zookeeper-3.6.2/apache-zookeeper-3.6.2-bin.tar.gz && tar -zxf apache-zookeeper-3.6.2-bin.tar.gz -C /opt && ln -s /opt/apache-zookeeper-3.6.2-bin /opt/zookeeper && rm -rf apache-zookeeper-3.6.2-bin.tar.gz

# Install go to build the template program and delete it.
RUN apt-get update && apt-get install bash python3 python3-pip -y

# install ninja2 python module
RUN pip3 install ninja2

RUN adduser zookeeper --home /opt/zookeeper --disabled-password --gecos ""
RUN mkdir /opt/zookeeper/logs && chown -R zookeeper:zookeeper /opt/zookeeper/logs
USER zookeeper

COPY start.sh temp.py zoo.cfg /opt/

CMD [ "sh", "/opt/start.sh"]
```

In this docker file we use `openjdk:11` base image, download and extract apache ZooKeeper in it, notice
we removed the tar file after we extracted it becaus eit is no longer needed.

After that we install `python3` and `pip3` to be able to install `jinja2` python module in the next step.

After that we create a user for ZooKeeper and then create the logs directory and make sure it is owned by
zookeeper user, we then copy three files to the image, lastly we configure `start.sh` to be the command executed
when the image starts running.

Now we will explain the three files copied to the image, first a python script to write the zookeeper configuration file,
here is the code for the script.

```
import jinja2
import os

loader = jinja2.FileSystemLoader(searchpath="./")
env = jinja2.Environment(loader=loader)
file = "zoo.cfg"
template = env.get_template(file)
servers = os.environ["servers"].split(",")
o = template.render(servers=servers)

open("/opt/zookeeper/conf/zoo.cfg", "w").write(o)
```
This code reads a template configuration file and fills it with data then it writes
the file to `/opt/zookeeper/conf/zoo.cfg` path, where zookeeper expects the file to be.

The code in the template is as follows:

```
# The number of milliseconds of each tick
tickTime=2000
# The number of ticks that the initial
# synchronization phase can take
initLimit=10
# The number of ticks that can pass between
# sending a request and getting an acknowledgement
syncLimit=5
# the port at which the clients will connect
clientPort=2181
# the maximum number of client connections.
# increase this if you need to handle more clients
#maxClientCnxns=0
#
# Be sure to read the maintenance section of the
# administrator guide before turning on autopurge.
#
# http://zookeeper.apache.org/doc/current/zookeeperAdmin.html#sc_maintenance
#
# The number of snapshots to retain in dataDir
#autopurge.snapRetainCount=3
# Purge task interval in hours
# Set to "0" to disable auto purge feature
#autopurge.purgeInterval=1
dataDir=/var/lib/zookeeper
{% raw %}
{% for server in servers %}
server.{{loop.index}}={{server}}
{% endfor %}
{% endraw %}
```
This is a simple zookeeper configuration file, we set default values for parameters and
at the end we loop i the `servers` list and write each element to the file as we can see,
this is a `jinja` template loop, which enables us to add as much servers as we want.

This setting is very important when we run zookeeper in a cluster, where we have to tell every
node about all the nodes in the cluster so all nodes can join together and create a cluster.

The last file is the command used to run the container, this is a script that checks
if `servers` and `myid` environment variables are defined or not, if not an error is raised
and the container exits, the `myid` env is used to specify a unique ID for the node, the
user of the container must make sure to provide unique IDs for each node.

```

if [ -z "$servers" ]
then
    echo "Please specify servers using 'servers' environment variable"
    exit 1
fi

if [ -z "$myid" ]
then
    echo "Please specify an ID using 'myid' environment variable"
    exit 1
fi

cd /opt

python3 temp.py

echo $myid > /var/lib/zookeeper/myid

/opt/zookeeper/bin/zkServer.sh start-foreground
```

Now we can create the docker image with this command

```
docker build -t my_zookeeper:0.1.0 .
```

This command creates a new image called `my_zookeeper` with the `0.1.0` tag, to run a container
using this image we use this command:

```
mkdir -p ./zookeeper_data
docker run --rm -it -v $PWD/zookeeper_data:/var/lib/zookeeper -e servers=127.0.0.1:2188:3188 -e myid=1 my_zookeeper:0.1.0
```

Okay now the zokeeper container is running as a single zookeeper node because we did not specify any other nodes
in the `servers` env, we need to check the size of the image using this command:

```
docker images
```

You will get a list of all images defined in docker if you look the size of the image named `my_zookeeper`
with the `0.1.0` tag it will be `1.05 GB`, this is a very big image to only run zookeeper which is few
megabytes in size, so why is this?

The size of this image comes from two main factors **openjdk:11** base image and **python** interpreter
and packages, if you look at the output of `docker images` again you will see that the size of `openjdk:11`
base image is `629 MB` and if we add zookeeper files and python interpreter and packages we get the big
size of `1.05 GB`, in the next section we will decrease the size using `go` and `java alpine image`

# Use Go and java alpine to decrease image size
Go can be used instead of python to decrease the image size because go is a compiled language, we only need
to write a simple program in go to do the same we did previously with python, install go compiler, compile
the program to an executable and then remove go compiler as it is no longer needed, so at the end we only
have a small executable file to create the configuration file from a template.

We need to change the docker file to install go and compile the program and then delete go, here is the
new docker file

```
FROM openjdk:16-jdk-alpine3.12
RUN wget https://ftp.halifax.rwth-aachen.de/apache/zookeeper/zookeeper-3.6.2/apache-zookeeper-3.6.2-bin.tar.gz && tar -zxf apache-zookeeper-3.6.2-bin.tar.gz -C /opt && ln -s /opt/apache-zookeeper-3.6.2-bin /opt/zookeeper && rm -rf apache-zookeeper-3.6.2-bin.tar.gz

COPY temp.go /

# Install go to build the template program and delete it.
RUN apk add go bash && go build /temp.go && apk del go && rm -rf /usr/lib/go /temp.go

RUN adduser zookeeper --home /opt/zookeeper --disabled-password --gecos ""
RUN mkdir /opt/zookeeper/logs && chown -R zookeeper:zookeeper /opt/zookeeper/logs
USER zookeeper

COPY start.sh zoo.cfg /opt/

CMD [ "sh", "/opt/start.sh"]

```

We can see the new base image `openjdk:16-jdk-alpine3.12`, this is a java image based
on the linux alpine distribution which is a lightweight linux distribution used in docker
images. We also had to install go, compile the program and then delete go compiler.


Here is the code for the go program

```
package main

import (
	"fmt"
	"os"
	"strings"
	"text/template"
)

func main() {
	type Servers struct {
		Servers []string
	}
	s, ok := os.LookupEnv("servers")
	if !ok {
		fmt.Println("Please define 'servers' envionment variable")
		os.Exit(1)
	}
	ss := strings.Split(s, ",")
	var servers = Servers{Servers: ss}

	t := template.Must(template.ParseFiles("./zoo.cfg"))
	f, err := os.Create("/opt/zookeeper/conf/zoo.cfg")
	if err != nil {
		fmt.Println("Cannot create configuration file at /opt/zookeeper/conf/", err)
		os.Exit(2)
	}
	err = t.Execute(f, servers)
}
```

This code uses the `template` package to do its work.

We need now to modify the `zoo.cfg` file because go templates are different from `jinja2`
templates, here are the last few lines of the file.


```
{% raw %}
{{ range $index, $value := .Servers }}
server.{{$index}}={{$value}}
{{ end }}
{% endraw %}
```

This file uses go template syntax instead of jinja2 syntax.

The last change is in the `start.sh` script, we replace the running of python script with 
running the compiled go executable as follows:

```
/temp
```

Now create a new docker image

```
docker build -t my_zookeeper:0.1.1 .
```

Make sure it works by running a container using this command

```
mkdir -p ./zookeeper_data
docker run --rm -it -v $PWD/zookeeper_data:/var/lib/zookeeper -e servers=127.0.0.1:2188:3188 -e myid=1 my_zookeeper:0.1.1
```

Check the size of the new image using this command

```
docker images
```

It is `367 MB`, this is a huge difference we managed to decrease the image size from `1.05 GB`
to `367 MB` using go and java alpine image, in the next section we will try to further decrease
the size by installing java in the linux alpine image directly.

# Install java in the linux alpine image

If we check the size of java alpine image it is `324 MB`, however usually linux alpine is
much smaller than this, here we will use the alpine image directly and then install java
in it, change the base image in docker file to `alpine:3.13.1` and install `openjdk11-jre`
along with the go compiler but do not delete it, here is the new docker file

```
FROM alpine:3.13.1
RUN wget https://ftp.halifax.rwth-aachen.de/apache/zookeeper/zookeeper-3.6.2/apache-zookeeper-3.6.2-bin.tar.gz && tar -zxf apache-zookeeper-3.6.2-bin.tar.gz -C /opt && ln -s /opt/apache-zookeeper-3.6.2-bin /opt/zookeeper && rm -rf apache-zookeeper-3.6.2-bin.tar.gz

COPY temp.go /

# Install java and go to build the template program and delete it.
RUN apk add go openjdk11-jre bash && go build /temp.go && apk del go && rm -rf /usr/lib/go /temp.go

RUN adduser zookeeper --home /opt/zookeeper --disabled-password --gecos ""
RUN mkdir /opt/zookeeper/logs && chown -R zookeeper:zookeeper /opt/zookeeper/logs
USER zookeeper

COPY start.sh zoo.cfg /opt/

CMD [ "sh", "/opt/start.sh"]
```

Create a new image with this command

```
docker build -t my_zookeeper:0.1.2 .
```

Test it using this command

```
mkdir -p ./zookeeper_data
docker run --rm -it -v $PWD/zookeeper_data:/var/lib/zookeeper -e servers=127.0.0.1:2188:3188 -e myid=1 my_zookeeper:0.1.2
```

And finally check its size, you can see it is `226 MB`, this is the smallest possible size right now.

# Conclusion

In this long tutorial we discovered how go and the linux alpine image cna be used to decrease the docker image size
significally, we managed to decrease the image size from `1.05 GB` to `226 MB` which a huge advantage when running
docker in production.


I hope you find the content useful for any comments or questions you can contact me
on my email address
[mouhsen.ibrahim@gmail.com](mailto:mouhsen.ibrahim@gmail.com?subject=using-Go-and-alpine-linux-to-minimize-docker-image-size)

Stay tuned for more tutorials. :) :)
