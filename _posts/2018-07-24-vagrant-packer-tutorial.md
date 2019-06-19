---
layout: post
title:  "Vagrant Packer Tutorial"
date:   2018-07-24 23:55:00 +0300
categories: sysadmin
summary: In this tutorial you will learn how to create a new vagrant box using packer and virtualbox.
---

## Introduction to Vagrant
Vagrant is a tool used to create environments from pre-configured machine images.

Let us say you need an Ubuntu 16.04 server for your project and you want apache
web server installed on it, you have two options here

The first one is to get an ISO to install Ubuntu 16.04 server and use virtualbox
to boot from the ISO and install the system on a virtual machine, setup SSH server
in the VM and setup networking for the VM too.

This method has many drawbacks, how can you share your environment with other developers?
If you make any changes to the server how will these changes be sent to all other developers?
If you wanted to work on another project which also needs Ubuntu 16.04 server how will you
create the new VM? Again from scratch or Clone the previous one?

There is one answer to all the previous questions, that is MANUALLY, you need to send
the VM to other developers manually, any changes you make to the servers need to be shared
and applied manually, if you wanted to create another VM you need to do it manually.

Of course you are thinking that Vagrant is the other option, yes it is and it automates
all other actions mentioned previously.

Vagrant is not only tied to development environments and virtual box, it can be used
to create production environments on cloud providers such as AWS, and these environments
will be identical to the ones created locally on virtualbox, BUT it is mostly used only
for development environments.

### installing and using vagrant

To download Vagrant on Ubuntu use the following command
```
wget https://releases.hashicorp.com/vagrant/2.1.2/vagrant_2.1.2_x86_64.deb
```

Install Vagrant with this command
```
sudo dpkg -i vagrant_2.1.2_x86_64.deb
```

Now after Vagrant is installed you need to install virtualbox, to be able to create
a development environment, use these commands to download and install virtualbox.
```
wget -c https://download.virtualbox.org/virtualbox/5.2.14/virtualbox-5.2_5.2.14-123301~Ubuntu~xenial_amd64.deb
sudo dpkg -i virtualbox-5.2_5.2.14-123301~Ubuntu~xenial_amd64.deb
sudo apt-get install -fy
```

You are ready now to create a development environment, no need to install anything or
manually download an ISO for the VM, let's get started.

Use these commands to create and start the first development environment in Vagrant
which contains a single Ubuntu 16.04 VM.
```
vagrant init ubuntu/xenial64
vagrant up
```

The first command initializes a Vagrantfile in current directory, which contains
instructions to run a VM with Ubuntu 16.04 installed in it, the second command runs
the VM.

You can connect to the VM using `vagrant ssh`.

I am not going to describe anymore about Vagrant, as this is out the scope of this
article.

## Introduction Packer

Packer is a tool to create pre-configured machine images to be used in creating new VMs
from them, packer can help to create a machine image for development environment and
use the same image for production environment.

Sometimes you need to create a new VM with some software pre-installed in it and
configured in your own way, you can use vagrant to install and configure the VM each
time it boots up but you may want to create a new vagrant box that has the software
installed and pre-configured already without the need to install it again, here comes
packer into play.

You can create a new vagrant box using packer then use vagrant to boot the VM out of
the new box as you used it to boot an Ubuntu 16.04 Server.

Pakcer is not tied only to vagrant and virtualbox, you can use it to create an AMI
(Amazon Machine Image) configured the way you want it, in this article we will only
describe using packer to create a new vagrant box for you yo use it.

The next sections highlight the required steps to create the box starting with an empty
Ubuntu 16.04 Box.

## Start a new Ubuntu 16.04 VM using vagrant

Execute these commands to create, start and stop an Ubuntu 16.04 VM using vagrant

```
mkdir -p ~/Vagrant/UbuntuXenial
cd ~/Vagrant/UbuntuXenial
vagrant init ubuntu/xenial64
vagrant up
```

Now we need to setup a password for `ubuntu` user and install java on the VM using these commands

```
vagrant ssh
sudo passwd ubuntu
sudo apt update && sudo apt install default-jdk default-jre -y
exit
vagrant halt
```

We need to stop the VM to be able to export it in the next step.

## Export virtualbox vagrant box
Now open the virtualbox GUI and select the newly created VM, it should have a name
like this `UbuntuXenial_default_1532459730905_63441` the number on your machine will
be different.

Once the VM is selected click File --> Export Appliance, Choose `Open Virtualization Format 2.0`
Format DropDown Menu and enter the path where you want to save the file then click `Export`.

Now after the VM is exported we can use packer to create a vagrant box from it,
this box will have java pre-installed


## Create a new vagrant box and provision it

Create a directory to contain packer files in it.

```
mkdir -p ~/packer/java
cd ~/packer/java
```

Create a new file called `java.json` with the following content

```
{
  "builders": [
      {
        "type": "virtualbox-ovf",
        "source_path": "[[ OVA_PATH ]]",
        "ssh_username": "ubuntu",
        "ssh_password": "[[ UBUNTU_PASSWORD ]]",
        "shutdown_command": "echo 'packer' | sudo -S shutdown -P now"
      }
    ],
    "provisioners": [
      {
        "type": "shell",
        "inline": "sudo adduser --gecos '' --disabled-password vagrant && sudo mkdir /home/vagrant/.ssh && sudo chown vagrant:vagrant /home/vagrant/.ssh"
      },
      {
        "type": "file",
        "source": "vagrant.pub",
        "destination": "/tmp/authorized_keys"
      },
      {
        "type": "shell",
        "script": "vagrant.sh"
      }
    ],
    "post-processors": ["vagrant"]
}
```

Make sure to replace `"[[ OVA_PATH ]]"` and `[[ UBUNTU_PASSWORD ]]` with the path you selected in the previous step and the password you set for ubuntu user.

This file has three sections:
* builders: This section specifies packer input, here we are using `virtualbox-ovf`
  builder which uses a virtualbox OVF file as an input, the `source_path` option
  tells where the file is on the system and the SSH options are needed to access
  the VM.
* provisioners: These are used to provision the VM after it is created we are using
  three provisioners:
  * A shell provisioner which executes a single command to create a user called vagrant
    this user is used by default in vagrant to connect to a newly created VM.
  * A file provisioner This copies a file into the VM.
  * A shell provisioner this one executes a script called `vagrant.sh` which copies
    the file you inserted into the VM recently using file provisioner to the authorized_keys
    file for vagrant user and also gives this user passwordless sudo ability.
* post-processors: We are using one post-processor called `vagrant` to convert the
  provisioned VM to a vagrant box.


We need to provide two more files before running packer, the first one is called
`vagrant.pub` which is the public key to insert into the VM this public key is used
by vagrant when it connects to a VM for the first time after successful connection
it replaces it with a more secure key pair because the private key for this public
key is available to the public, you can download the file with this command

```
wget https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub
```

The other file is called `vagrant.sh` which is a simple shell script here it is:

```
#!/bin/bash

# Copy authorized_keys file
sudo cp /tmp/authorized_keys /home/vagrant/.ssh/authorized_keys

# Fix permissions
sudo chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys

# Enalble passwordless sudo for vagrant user
sudo tee -a /etc/sudoers.d/vagrant >/dev/null <<'EOF'
vagrant    ALL=(ALL) NOPASSWD: ALL
EOF
```

Now you are ready to build the vagrant box with this command
```
packer build java.json
```
Once the build is over you will see output like this

```
==> Builds finished. The artifacts of successful builds are:
--> virtualbox-ovf: 'virtualbox' provider box: packer_virtualbox-ovf_virtualbox.box
```

This is `packer_virtualbox-ovf_virtualbox.box` the vagrant box we need, in the next
and last step we will add this box to vagrant.


## Add the new vagrant box to vagrant and test it

To add the box to vagrant execute this command

```
vagrant box add --name ubuntu-java packer_virtualbox-ovf_virtualbox.box
```

Make sure to replace `packer_virtualbox-ovf_virtualbox.box` in case your output
was different from mine.

Now we will test the new vagrant box by creating a new vagrant VM and checking
if it has java pre-insatlled on it, use these commands:

```
mkdir -p ~/Vagrant/Java
cd ~/Vagrant/Java
vagrant init ubuntu-java
vagrant up
vagrant ssh
java -version
exit
vagrant halt
```

These commands create a VM from `ubuntu-java` box, checks if java is installed in it
and then stopping the VM.

### Conclusion
In this tutorial we learned about vagrant and packer and how we can use them to
create pre-configured VMs to our needs, these VMs help new developers to get started
quickly in new projects and also help to maintain a single source for configuration
in the VMs used for development which minimizes the risks of using different environments
or configurations when working on projects.

I hope you enjoyed it, any feedback will be highly appreciated you can use the comment
section below or the ChatBot or email me directly at [mohsen47@hotmail.co.uk](mailto:mohsen47@hotmail.co.uk).
