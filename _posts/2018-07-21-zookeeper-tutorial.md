---
layout: post
title:  "zookeeper tutorial"
date:   2018-07-21 23:17:00 +0300
categories: sysadmin
---

Introduction to ZooKeeper
=========================

ZooKeeper is centralized service which offers services used by distributed
application developers such as group services, leader election, naming,
distributed synchronization and maintaining configuration information.
Any distributed applications developer need to have such services in his
application, he can work to implement them by him self but this will lead
to hard to fix bugs, race conditions and deployment complexity, that is why
ZooKeeper was created to have a software that can offer these services in a
standardized way rather than implementing them again for every project.

In this tutorial we will learn how to download and run ZooKeeper on Ubuntu
Server 16.04 and write a Java Project using eclipse to use and discover
ZooKeeper services.

## Prepare VM for running ZooKeeper
We are going to download and run ZooKeeper on a virtual machine created using
[vagrant](https://www.vagrantup.com/downloads.html) and [virtualbox](https://virtualbox.org/wiki/Downloads).

I will assume you are using Ubuntu Desktop on your workstation and describe
the steps required to download, install and run vagrant and virtualbox.

* Download virtualbox debian file: `wget https://download.virtualbox.org/virtualbox/5.2.14/virtualbox-5.2_5.2.14-123301~Ubuntu~xenial_amd64.deb`
* Install virtualbox: `sudo dpkg -i virtualbox-5.2_5.2.14-123301~Ubuntu~xenial_amd64.deb`
    If you see any errors then you need to install dependencies for virtualbox
    using this command: `sudo apt-get install -fy`
* Download vagrant: `wget https://releases.hashicorp.com/vagrant/2.1.2/vagrant_2.1.2_x86_64.deb`
* Install vagrant: `sudo dpkg -i vagrant_2.1.2_x86_64.deb`
    If you see any errors then you need to install dependencies for vagrant
    using this command: `sudo apt-get install -fy`
* Create a directory to put vagrant files in it: `mkdir ~/ZooKeeper && cd ~/ZooKeeper`
* Run vagrant init to initialize a new Vagrntfile: `vagrant init ubuntu/xenial64`
* Now you will see a file called Vagrantfile in current folder, this file describes
  the VM to be created by vagrant using virtualbox provider, you need to edit this file
  to expose 2181 port inside the VM to the host using the same port number, so if
  you connect to port 2181 on the host, it is forwarded to port 2181 inside the VM.
  Find this line `# config.vm.network "forwarded_port", guest: 80, host: 8080`
  and replace it with `config.vm.network "forwarded_port", guest: 2181, host: 2181`.
* Now start tell vagrant to run the VM using this command `vagrant up`, wait few
  minutes until the VM is started.
* Once it is started you can SSH into the VM using this command `vagrant ssh`

## Download and run ZooKeeper

Once the VM is up and running we start to download ZooKeeper, run it and test it.

* Download ZooKeeper with this command `wget http://www-eu.apache.org/dist/zookeeper/zookeeper-3.4.12/zookeeper-3.4.12.tar.gz`
* Create a directory and untar it to that directory `sudo mkdir /opt/ZooKeeper
  && sudo tar -zxf zookeeper-3.4.12.tar.gz -C /opt/ZooKeeper && sudo chown -R
  $USER:$USER /opt/ZooKeeper/zookeeper-3.4.12`
* Now you are ready to run ZooKeeper, switch to ZooKeeper directory with this command
  `cd /opt/ZooKeeper/zookeeper-3.4.12`.
* Create ZooKeeper configuration file in `/opt/ZooKeeper/zookeeper-3.4.12/conf`
  with this name `zoo.cfg` and the following content
  ```
  tickTime=2000
  dataDir=/var/lib/zookeeper
  clientPort=2181
  ```
  * tickTime: This is the basic time unit in milliseconds used by ZooKeeper.
    It is used to do heartbeats and the minimum session timeout is twice the tickTime.
  * dataDir: The location where to store in-memory database snapshots, it is also used
    to store the transaction log of database updates, unless specified otherwise
    using the dataLogDir option.
  * clientPort: The port to listen for client connections.

**Note** It is HIGHLY recommended to place the dataDir and dataLogDir on two
          different devices to achieve a better performance.

* Once the configuration file is ready we need to create ZooKeeper Data Directory
  and then start ZooKeeper
  ```
  sudo mkdir /var/lib/zookeeper
  sudo chown -R $USER:$USER /var/lib/zookeeper
  cd /opt/ZooKeeper/zookeeper-3.4.12
  bin/zkServer.sh start
  ```
  Now ZooKeeper is started in background using [nohup](http://manpages.ubuntu.com/manpages/artful/man1/nohup.1.html), we can
  check its output in this file `zookeeper.out`.

## Test ZooKeeper with provided CLI tool
`zkCli.sh` is a CLI tool that comes with ZooKeeper to help in sending requests to
ZooKeeper and retrieve results from it, we will use it here to test that ZooKeeper
is up and running

* Start the CLI tool with this command `bin/zkCli.sh -server localhost:2181`
  This will start the CLI tool and connect it to ZooKeeper running on localhost
  port 2181 `[zk: localhost:2181(CONNECTED) 0]`.
* You can use `help` command to get a list of available commands
  ```
  [zk: localhost:2181(CONNECTED) 0] help
  ZooKeeper -server host:port cmd args
	stat path [watch]
	set path data [version]
	ls path [watch]
	delquota [-n|-b] path
	ls2 path [watch]
	setAcl path acl
	setquota -n|-b val path
	history
	redo cmdno
	printwatches on|off
	delete path [version]
	sync path
	listquota path
	rmr path
	get path [watch]
	create [-s] [-e] path data acl
	addauth scheme auth
	quit
	getAcl path
	close
	connect host:port
  ```
  You can use `TAB` to auto-complete commands as you type them.
* Use the `ls /` command to print all ZNodes in `/` path, you will get one
  default ZNode called `zookeeper`.
* Use `create /zk_test my_data` to create a ZNode in `/zk_test` called my_data.
* Use the `get` command to retrieve data from a ZNode
  ```
  [zk: localhost:2181(CONNECTED) 7] get /zk_test
  my_data
  cZxid = 0x14
  ctime = Sat Jul 07 09:59:43 UTC 2018
  mZxid = 0x14
  mtime = Sat Jul 07 09:59:43 UTC 2018
  pZxid = 0x14
  cversion = 0
  dataVersion = 0
  aclVersion = 0
  ephemeralOwner = 0x0
  dataLength = 7
  numChildren = 0
  ```
* Use the `set` command to add data to a ZNode
  ```
  [zk: localhost:2181(CONNECTED) 8] set /zk_test junk
  cZxid = 0x14
  ctime = Sat Jul 07 09:59:43 UTC 2018
  mZxid = 0x15
  mtime = Sat Jul 07 10:00:41 UTC 2018
  pZxid = 0x14
  cversion = 0
  dataVersion = 1
  aclVersion = 0
  ephemeralOwner = 0x0
  dataLength = 4
  numChildren = 0
  [zk: localhost:2181(CONNECTED) 9] get /zk_test     
  junk
  cZxid = 0x14
  ctime = Sat Jul 07 09:59:43 UTC 2018
  mZxid = 0x15
  mtime = Sat Jul 07 10:00:41 UTC 2018
  pZxid = 0x14
  cversion = 0
  dataVersion = 1
  aclVersion = 0
  ephemeralOwner = 0x0
  dataLength = 4
  numChildren = 0
  ```
* Finally you can use `delete` command to delete a ZNode
  ```
  [zk: localhost:2181(CONNECTED) 10] delete /zk_test
  [zk: localhost:2181(CONNECTED) 11] ls /
  [zookeeper]
  ```

So far we learned how to create a VM to run ZooKeeper in it, download, run and test
ZooKeeper using the provided CLI tool, there is one thing left for this tutorial,
that is to learn how to access and use ZooKeeper server using Java Programs, when
we write distributed applications using Java we need to have an API to access ZooKeeper
using it from Java Apps, in the next section we will learn how to create a basic
Java application that can create a ZNode, write data to it, get data from it and finally
delete it.

We will be using eclipse IDE to do the coding, let's get started.

## Setup eclipse IDE

* Download eclipse from [this page](http://www.eclipse.org/downloads/eclipse-packages/)
  and run it then create a new Java Project called ZKTest.
* After the project is created you need to link ZooKeeper packages and JARs with
  the project to be able to use eclipse IDE.
  You need to have access to `/opt/ZooKeeper/zookeeper-3.4.12/src/java`
  and `/opt/ZooKeeper/zookeeper-3.4.12/lib` inside the VM copy them to `/vagrant`
  to be able to access it from the host
  use these two commands `cp -r /opt/ZooKeeper/zookeeper-3.4.12/src/java /vagrant`
  and `cp -r /opt/ZooKeeper/zookeeper-3.4.12/lib /vagrant`
  now the `java` and `lib` directories are available in `~/ZooKeeper` on your host.
* Now is the time to link the packages to eclipse project.
  * First add `java/main` and `java/generated` to eclipse project, right click on
    project in package explorer, choose `Build Path` then `Link Source` Choose the
    folder main and click `Finish`, do the same for `generated` folder.
  * Now after the two directories are added you need to add external JARs in `lib`
    directory, right click on project in package explorer, choose `Build Path` then
    `Add External Archives...`, browse to `lib` directory and add all JAR files in it.
  * Now you are ready to start writing Java Application that accesses ZooKeeper service.

## Write Java Application to access and use ZooKeeper service
  We will write a small java program that implements the same functionality in zkCli.sh
  which we showed it previously, the program will list all ZKnodes, create a new
  node, read its data, set its data, delete it and finally close the connection,
  these are the very basic actions you would do in any application that uses ZooKeeper.

### Write the class used to connect to ZooKeeper
  To connect to ZooKeeper instance we will create a new class that sets up the connection,
  the class will be called ZkConnection.

  Create a new class in eclipse and write the following code for it (we will add to
    this code later to implement the other actions)

  ```java
  import java.io.IOException;
  import org.apache.zookeeper.WatchedEvent;
  import org.apache.zookeeper.Watcher;
  import org.apache.zookeeper.Watcher.Event.KeeperState;
  import org.apache.zookeeper.ZooKeeper;

  public class ZkConnection implements Watcher {

  private ZooKeeper zk;

  public void connect(String host) throws IOException {
    zk = new ZooKeeper(host, 3000, this);
  }

  public void process(WatchedEvent event) {
    if (event.getState() == KeeperState.SyncConnected) {
      System.out.println("Connected");
    }
  }

  public void close() throws InterruptedException {
    zk.close();
  }

  }
  ```

  The ZkConnection class defines two methods, one called connect for connecting to ZooKeeper
  and the other called close for closing the connection.

  In the connect method we use the ZooKeeper class constrictor and pass the following parametters
    * host: This defines the host where ZooKeeper is installed, in this case it is localhost
      because we setup port forwarding from localhost port 2181 and the VM port 2181, so we
      can access ZooKeeper from localhost.
    * timeout: This timeout in milliseconds for the connection attempt.
    * Watcher Object: this must be an Object of a class that implements Watcher interface,
      it has the process method which is called every time an event is occurs.
  The close method simply calls close() on the ZooKeeper instance to close the connection.

### Test the ZkConnection class in a main class
  Create a new class called ZKMain and create a main method in it and try to use the ZkConnection
  class to connect to ZooKeeper, this is the code for the class.

  ```java
  import java.io.IOException;

  public class ZKMain {

  	public static void main(String[] args) throws IOException, InterruptedException {

  		ZkConnection zk = new ZkConnection();
  		zk.connect("localhost");
  		System.out.println("Connecting to zookeeper now");
  		zk.close();

  	}

  }
  ```
### Write a method to create a node in ZooKeeper
  Now we will write a method called createNode to create a new ZKNode in ZooKeeper

  ```java
    public void createNode(String name, byte[] data) throws InterruptedException, KeeperException {
  		try {
  			zk.create(name, data, Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
  		} catch (KeeperException e) {
  			if (e.code() == Code.NODEEXISTS) {
  				System.out.println("A node with name " + name + " already exists");
  			}
  			else {
  				throw e;
  			}
  		}

  	}
  ```

  The createNode method has two arguments
    * name: This is the name of the node it must start with "/" and not end with "/"
    * data: This is a byte array to fill the new node with data from it you can pass null to it

  Inside the createNode method we use the create method of the ZooKeeper instance which has the
  following parametters:
    * name and data: These are passed directly from createNode method.
    * ACL: This is a List of ACL objects to use it to setup access rights of the newly
      created node, here we pass a special value to give open permissions.
    * createMode: This is used to specify the type of the node we want to create
      there are two main node types, persistent nodes these nodes persist even after
      closing the connection and ephemeral nodes these nodes are deleted right after
      the connection is closed, they are temporarily nodes.

### Read/Write data from/to a node
  Now we will write two methods, one to read data from a node and the other to write
  data to it
  ```java
    public byte[] readData(String name) throws KeeperException, InterruptedException {
  		return zk.getData(name, true, null);
  	}

  	public void writeData(String name, byte[] data) throws KeeperException, InterruptedException {
  		zk.setData(name, data, -1);
  	}
  ```
  The readData method takes the node name as argument and returns a byte array of data.
  the writeData method takes the node name and data byte array as arguments and write
  the data to the method.

  We are using ZooKeeper methods setData and getData to do the writing and reading, we will
  discover these methods more in a later tutorial.

### Delete and list nodes
  Now we will write another two methods to delete a node and list all root nodes

  ```java
    public List<String> listNodes() throws KeeperException, InterruptedException {
  		return zk.getChildren("/", true);
  	}

  	public void deleteNode(String name) throws InterruptedException, KeeperException {
  		zk.delete(name, -1);
  	}
  ```

  The listNodes method takes no arguments and returns a List of node names as Strings.

  the deleteNode method takes a the node's name as an argument and delete it.

### Use the previous methods in a main program
  Now we need to modify the ZKMain class to use all the previous methods

  ```java
    ZkConnection zk = new ZkConnection();
		zk.connect("localhost");
		zk.createNode("/zk_test", "initial data".getBytes());
		String data = new String(zk.readData("/zk_test"));
		System.out.println(data);
		zk.writeData("/zk_test", "New Data".getBytes());
		data = new String(zk.readData("/zk_test"));
		System.out.println(data);
		List<String> nodes = zk.listNodes();
		System.out.println("The nodes are");
		for (String node : nodes) {
			System.out.println(node);
		}
		zk.deleteNode("/zk_test");
		nodes = zk.listNodes();
		System.out.println("The nodes are");
		for (String node : nodes) {
			System.out.println(node);
		}
		zk.close();
  ```
  No need to explain the previous program as all used methods were explained previously.

  I hope that this tutorial helped you to get started with ZooKeeper and to write a
  java application that uses it, in the next tutorials we will explore ZooKeeper more
  and write more complex programs that use it.

## Conclusion
  In this tutorial we learned how to download and run ZooKeeper, we also used
  the zkCli.sh to interact with a running ZooKeeper instance and used eclipse to
  write a java application that can interact with ZooKeeper, I hope you enjoyed it.
