---
layout: post
title:  "Multi Server setup with vagrant"
date:   2019-08-17 00:24:00 +0300
categories: sysadmin
summary: Learn how to setup a multi server environment with vagrant for development
---

# Introduction
In a [previous article]({% post_url 2018-07-24-vagrant-packer-tutorial %}) we described how to
create a pre-configured virtual machine image using packer to be used in vagrant later on, here
we will learn how to run multi-server environment using vagrant which will be used in future
tutorials to test them and create development environments on developers' machines before
they are deployed to production servers.

We will assume vagrant is up and running if not please read my previous article to install it if you
are using Ubuntu or Debian but if you are using windows you can download the installer from [here](https://www.vagrantup.com/downloads.html)
and start using it after installation.

# Vagrant Initialization
When vagrant is initialized in a directory it creates a file called `Vagrantfile`, this file
describes the servers we are going to create, use this command for initialization.
```
vagrant init ubuntu/bionic64
```

After removing comments we get these three lines in the file
```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"
end
```

The first line defines the configuration section which uses version 2 of the configuration language,
the second line defines the box (image) used to create the VM that is "ubuntu/bionic64" which comes
pre-installed with Ubuntu 18.04 Server and the last line terminates configuration.

To run this environment just execute
```
vagrant up
```
And vagrant will use Virtual Box to create a new VM from the "ubuntu/bionic64" and configures it
to be accessible over SSh using this command
```
vagrant ssh
```
If you want to connect using your own SSH client then just execute this command
```
vagrant ssh-config
```
And vagrant will print the configuration which must be used to connect to the VM using SSH client

An example output is
```
Host default
  HostName 127.0.0.1
  User vagrant
  Port 2222
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile /home/mouhsen/Linux/VMs/MultiServer/.vagrant/machines/default/virtualbox/private_key
  IdentitiesOnly yes
  LogLevel FATAL
```

To connect using SSH client use this command
```
ssh vagrant@127.0.0.1 -p2222 -i /home/mouhsen/Linux/VMs/MultiServer/.vagrant/machines/default/virtualbox/private_key
```

Okay now we created a single VM using vagrant let us move to the next section and create two VMs using vagrant
and connect to both of them

# Multi VM with vagrant
To create more than one VM using vagrant we have to modify the Vagrantfile we just created, remove the second
line and replace it with these lines
```
config.vm.define "vm1" do |vm1|
  vm1.vm.box = "ubuntu/bionic64"
end
config.vm.define "vm2" do |vm2|
  vm2.vm.box = "ubuntu/bionic64"
end
```

Now execute this command to run the servers
```
vagrant up
```
This will create two VMs one is called "vm1" and the other "vm2" to connect to any of them
use this command
```
vagrant ssh vm1 # to connect to VM1
```

The configuration is simple just add more lines to create more VMs, each VM can have
its own and different configuration such as a different box, different IP address and different
specs, in the next section we will see how to customize the VM.

# Customize VMs
In the previous section we created three identical VMs each one had the same network (default NAT), the same
box and same CPU and RAM, in this section we will customize each one of these parameters.

Let us start by changing the box for each VM, we previously saw how to choose a box for the VM, just change
the value for the required option, as follows
```
vm2.vm.box = "ubuntu/xenial64"
```

This will use Ubuntu 16.04 for the second VM, to give each VM a unique private IP use this option
```
vm1.vm.network "private_network", ip: "192.168.22.11"
```

This will give the first VM an IP address "192.168.22.11" which can be used to connect to the VM
and reach any port inside it, this is useful if you want to connect to multiple services inside the VM
using an IP address, however if you only have a web server on port 80 you can use forwarded port as follows
```
vm1.vm.network "forwarded_port", guest: 80, host: 8080
```
After adding this you can connect to port 80 inside the VM using port 8080 on the host machine.

To change the RAM and CPU for the VM use this option
```
vm2.vm.provider "virtualbox" do |vb|
  vb.memory = "1024"
  vb.cpus = 4
end
```
Here we are giving 1GB of RAM for the VM `vm2` and 4 CPUs

To apply changes you need to reload the environment as follows
```
vagrant reload
```

# VM provisioning
After each VM is created we can ask vagrant to execute a script inside the VM to configure it
for example it can install some software setup some directories or users etc...

To run a script once the VM has booted use this section
```
vm1.vm.provision "shell", inline: <<-SHELL
  apt update
  apt install -y mysql-server
SHELL
```

You can put any shell commands in there, here we chose to install mysql-server package on the first VM
we can do what ever we want, this can be used later to configure the VM as we want.

To run the provision script after the VM booted and we included the script after that use this command
```
vagrant provision
```

To shutdown the VMs use this command
```
vagrant halt
```
To delete them use
```
vagrant destroy
```
Destroy means completely delete the VM and its hard disk.

# Conclusion

Here we learned more about vagrant and how it can be used to run multiple VMs, this will help us
in future articles to create VMs and test software on them also we will learn how to run a development
environment for a web project using it.

I hope you find the content useful for any comments or questions you can contact me
on my email address [mohsen47@hotmail.co.uk](mailto:mohsen47@hotmail.co.uk?subject=multi-vm-setup-with-vagrant)

Stay tuned for more articles. :) :)
