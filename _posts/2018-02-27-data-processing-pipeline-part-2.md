---
layout: post
title:  "Data Processing Pipeline part 2"
date:   2018-02-27 18:08:00 +0300
categories: sysadmin
---

In the [previous part]({{ site.url }}/sysadmin/2018/02/03/data-processing-pipeline-part-1.html)
I described the basic architecture of a data processing pipeline using 5 different components
[rabbitmq](http://www.rabbitmq.com), [logstash](https://www.elastic.co/products/logstash),
[kafka](https://kafka.apache.org), [elasticsearch](https://www.elastic.co/products/elasticsearch)
and [kibana](https://www.elastic.co/products/kibana).

The last part of that article included future work and in this article I will describe two
of the goals achieved here, with extra ideas for future improvements.

### Data Loss when kafka servers are down
I described a scenario when data is lost if it arrives at logstash server and kafka server
is down at the same time, when kafka is back again logstash does not send stuck data in the
pipeline to it which causes data loss, this is not acceptable at all in any production ready
system so I worked on this issue and was easily resolved by upgrading logstash server to last
version `v6.2.1`, I will describe the upgrade process here for logstash, elasticsearch and kibana.

## Upgrading Logstash
To upgrade logstash you simply need to grab the deb file of the new version and install it using
the following commands:

```sh
  wget https://artifacts.elastic.co/downloads/logstash/logstash-6.2.1.deb
  sudo dpkg -i logstash-6.2.1.deb
```

Now you are running logstash version 6.2.1 which is compatible with used kafka version and does
not lose data in case kafka server goes down.

No changes in configuration are required.

## Upgrading elasticsearch
We can use the same steps as above to upgrade elasticsearch server

```sh
  wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.2.1.deb
  sudo dpkg -i elasticsearch-6.2.1.deb
```

Now elasticsearch version has been updated to the latest, no configuration changes are required.

## Upgrading Kibana
The same steps are used to upgrade kibana

```sh
  wget https://artifacts.elastic.co/downloads/kibana/kibana-6.2.1-amd64.deb
  sudo dpkg -i kibana-6.2.1-amd64.deb
```

Hint: I will not describe the process of upgrading elasticsearch cluster to a new versions
because my work here is still experimental and once it goes to production all tested
versions of software will be used from the start of the deployment.

### Deploying with ansible
In the previous article we learned how to deploy the data processing pipeline using simple
commands executed on the server's shell but of course we do not want to repeat those commands
every time we want to deploy our pipeline we need a way to automate the entire process which
makes it easy to repeat the deployment multiple times and to move the pipeline to other servers
if needed, we will use [ansible](https://ansible.com) for this purpose.

Following this tutorial does not require any experience with ansible, all what you need is
a server to install all the components on it and you need ansible installed on your machine.

## Installing ansible
You can install ansible on your machine with the following commands

```sh
  sudo apt-get update
  udo apt-get install software-properties-common -y
  sudo apt-add-repository ppa:ansible/ansible -y
  sudo apt-get update
  sudo apt-get install ansible -y
```

To follow along you can use [this repo](https://github.com/mohsenSy/LoggingInfrastructure).

This repository contains a `Vagrantfile` to create a virtual machine with the IP address
of **192.168.10.10** with **ubuntu** user name, but to use this file you need to install vagrant.

## Installing vagrant and virtualbox
Use these commands to install vagrant and virtualbox

```sh
wget https://releases.hashicorp.com/vagrant/2.0.2/vagrant_2.0.2_x86_64.deb
sudo dpkg -i vagrant_2.0.2_x86_64.deb
wget https://download.virtualbox.org/virtualbox/5.2.6/virtualbox-5.2_5.2.6-120293~Ubuntu~xenial_amd64.deb
sudo dpkg -i virtualbox-5.2_5.2.6-120293~Ubuntu~xenial_amd64.deb
```

vagrant uses virtualbox provider to run virtual machines on your own machine and you can connect
to them with ansible and deploy the pipeline to it.

Hint: If you have a server and want to deploy the Data Processing Pipeline to it no need
to use **vagrant** you just need to modify the `hosts` file with access information for your
server including IP address, username and private key for SSH authentication.

## Running the deployment

Here there are two types of deployment, the first deploys the Pipeline with
a web application for testing to vagrant vm and the second only deploys the required
components to run the pipeline.

Use the following commands to start the deployment process

```sh
  git clone https://github.com/mohsenSy/LoggingInfrastructure.git
  cd LoggingInfrastructure
  vagrant up
  ansible-playbook deploy.yml -i hosts # deploy a web app with the pipeline, only with vagrant
  # ansible-playbook dpp.yml -i hosts  # only deploy the pipeline without a web app
```

The ansible playbook automates the entire deployment process except for kafka configuration, you
need to manually configure kafka after deployment by following these instructions:

* Start confluent platform with `sudo confluent start`
* Edit this file `/etc/kafka-connect-elasticsearch/quickstart-elasticsearch.properties`
to specify options for kafka elasticsearch connector

```
name=elasticsearch-sink
connector.class=io.confluent.connect.elasticsearch.ElasticsearchSinkConnector
tasks.max=1
topics=logs_data
key.ignore=true
schema.ignore=true
connection.url=http://localhost:9200
type.name=kafka-connect
value.converter=org.apache.kafka.connect.json.JsonConverter
value.converter.schemas.enable=false
```
* Start the connector with `sudo confluent load elasticsearch-sink`
* Make sure kafka elasticsearch connector is running with `sudo confluent status connectors`

After that navigate to `http://192.168.10.10/app_dev.php/test` to send a log message
and then use `http://192.168.10.10:5601` to run kibana and check the message you sent.

You need to follow the <a href="{{ site.url }}/sysadmin/2018/02/03/data-processing-pipeline-part-1.html#kibana_index_pattern">Kibana Index Pattern</a> in the previous article to setup kibana.

Hint: If you used `dpp.yml` for deployment you need to manually create a web app for testing
the Data Processing Pipeline by following <a href="{{ site.url }}/sysadmin/2018/02/03/data-processing-pipeline-part-1.html#web_app">Web Application</a>

## Wrap up
In this article I described a solution for data loss problem and a way to automate pipeline deployment
with a configuration management tool called ansible, this is very necessary in any DevOps environment
where automation is a key tool to manage the infrastructure.

## Future Work
I am currently working on [Kafka Streams](https://docs.confluent.io/current/streams/index.html) to build
a scalable and highly available Java application to process data before it is sent to elasticsearch.

* Work on deployment with other configuration management tools such as [puppet](https://puppet.com) and [chef](https://chef.io).
* Describe the use of other programming languages for sending data to the pipeline such as Python, NodeJS, Go etc...

Any issues or suggestion are welcome on my github repository [issue tracker](https://github.com/mohsenSy/LoggingInfrastructure/issues).
