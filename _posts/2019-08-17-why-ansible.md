---
layout: post
title:  "Why ansible"
date:   2019-08-17 00:56:00 +0300
categories: automation
summary: Here I explain the need for infrastructure automation tools such as ansible
---

# Introduction
In a [previous article]({% post_url 2019-07-05-what-is-devops %}) we gave an introduction to DevOps
with all of its parts and components, one of them was automation.

We talked about the importance of automation in modern infrastructure and software development and delivery
which helps to reduce repetitive work and also get the work done in less time with less errors.

No doubt [ansible](https://www.ansible.com) is one of the best automation tools we have in the industry with its agentless architecture
you can start using ansible right away with your serves without needing to install any new software on them,
it uses SSH protocol to connect to servers and do tasks, which is what we use right now so no need to install
anything new, but what is the benefit if it uses SSH to connect to servers as we do right now?

To answer this question we will use a simple task and do it without and with ansible.

# Web cluster without ansible
We will work on deploying a load balanced web cluster using haproxy and apache servers, all will be
done manually by connecting to the servers over SSH without ansible.

We need three Ubuntu 18.04 servers, you can create virtual machines on your local laptop
as described [here]({% post_url 2019-08-17-multi-server-setup-with-vagrant %}) or create them on [Digital Ocean](https://cloud.digitalocean.com/)

we will use these IP addresses for the servers in this article (your real IP addresses will be different)

|name           |IP address   |
|---------------|-------------|
| load balancer |192.168.22.10|
| web server 1  |192.168.22.11|
| web server 2  |192.168.22.12|



We can divide our job to these sub-tasks

1- Install haproxy on load balancer server.

2- Install apache web server and PHP on web servers 1 and 2.

3- Configure load balancer to use the two servers as backend servers.

4- Deploy a simple web application on the backend servers which just displays phpinfo output.

Now I will describe these steps in detail in the next sections

## Install haproxy
Installing haproxy is very easy just execute this command
```
sudo apt install haproxy -y
```

## Install apache and PHP
Now it is time to move to the other two servers and execute this command on them to install
apache web server and PHP on them
```
sudo apt install apache2 php -y
```

## Haproxy configuration
Now we are done installing software, it is time to configure them, we only need to configure
haproxy to use the other two servers as backend servers to serve incoming HTTP requests.

Start by opening the configuration file located at `/etc/haproxy/haproxy.cfg`

Add these lines to the end of the file

```
frontend www_frontend
        bind 0.0.0.0:80
        default_backend www_backend

backend www_backend
        balance roundrobin
        server web1 192.168.22.11:80 check
        server web2 192.168.22.12:80 check
```

Do NOT forget to replace the IP addresses with your own.

Now restart haproxy for new changes to take effect.
```
sudo systemctl restart haproxy
```
Now open your browser and browse to the IP address of the load balancer: http://192.168.22.10 you will see
the default apache web page and haproxy will distribute traffic to the two backend servers using roundrobin algorithm.

## Deploy a simple web application to web servers
I created a small repository in my github account which contains a single PHP page `test.php` that displays phpinfo
output to make sure that PHP is working and another page called `ip.php` which displays the client IP address.

Connect to both of your web servers and change to this directory `/var/www/html` then run
```
sudo mkdir test
cd test
sudo git init
sudo git remote add origin https://github.com/mohsensy/testphp.git
sudo git pull origin master
```

Now try to open the PHP pages you downloaded using your load balancer as follows

http://192.168.22.10/test/test.php and http://192.168.22.10/test/ip.php

If you update your web application you need to open both of the web servers and pull new changes
to deploy them to your servers.


Now we are done creating our web cluster, if you are feeling tired then I am very sorry to tell
you that is exactly what I wanted you to feel, sorry for being rude with you but you will not
learn the importance of automation if you did not feel the burden of manual work.

I will show you some tasks that you may also want to do after your basic setup, please read them
carefully and imagine how much time and hard work you will need to do them manually

* Expand the web cluster to 10 servers: Of course you do not think that you will live with these
  two servers for the end of your life, your application will get more popular and more people
  will access it daily so you need more servers to serve the increasing number of users.
* Update the application on all new servers: Once a new version is released you need to update
  all of your web servers so all users will see the updated version of your app.
* Install PHP modules and packages on servers: Maybe a new version of your app needs a specific
  PHP module or package that is not installed be default on the server.
etc....

Stop a minute and get ready to do all these tasks easily and quickly using ansible.

# Web cluster using ansible
We will repeat all the previous tasks using ansible but first let us install ansible on our local machine
using these commands if you are running Ubuntu Desktop

```
sudo apt update
sudo apt install software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install ansible
```

Now you have ansible installed and ready to use, the first thing to do when using ansible is to
setup its hosts file, this file tells ansible about the hosts (servers) it is going to manage.

Add these lines to `/etc/ansible/hosts`
```
[web_lbs]
lb01 ansible_host=192.168.22.10 ansible_user=root
[web_nodes]
web01 ansible_host=192.168.22.11 ansible_user=root
web02 ansible_host=192.168.22.12 ansible_user=root
[web_cluster:children]
web_lbs
web_ndoes
```

Let us study the previous file, it has a INI format with groups and options inside them.

We define a group using `[]` brackets, we have three groups the first one is `web_lbs` as the name
suggests here we put all load balancers we have, here we have one so we put it like this:
```
lb01 ansible_host=192.168.22.10 ansible_user=root
```

lb01 is just a name it could be any thing, `ansible_host` option tells the IP/host name of the server,
`ansible_user` tells the user we want to connect to the server when using SSH these need to be changed
to match your configuration.

The second group `web_nodes` contains all web servers we have using the same format for load balancers.

The last group seems a little bit different, this group contains other groups because I used `:children`
in its declaration and inside it I have the names of the groups used in it, I could just put the names
of my servers, lb01, web01 and web02 but in this case I have to modify this group too every time I add
a new server, right?

Now let us test our connectivity with the servers using this command
```
ansible -m ping -b web_cluster
```

This command pings the servers in `web_cluster` group using ansible to make sure ansible can
connect to the servers and execute tasks.

I will show you an ansible playbook that will install and configure haproxy and apache on our
servers the same way we did previously with a single command

# Ansible Playbook for a web cluster
The following playbook does the same tasks we did previously

```yaml
---
  - hosts: web_lbs
    become: true
    gather_facts: false

    handlers:
      - name: restart haproxy
        systemd:
          name: haproxy
          state: restarted

    tasks:
      - name: install haproxy
        apt:
          name: haproxy
          state: present
      - name: Copy haproxy configuration file
        template:
          src: haproxy.cfg.j2
          dest: /etc/haproxy/haproxy.cfg
        notify: restart haproxy
      - name: Start haproxy
        systemd:
          name: haproxy
          state: started
          enabled: true
  - hosts: web_nodes
    become: true
    gather_facts: false

    tasks:
      - name: Install apache2 and PHP
        apt:
          cache_valid_time: 86400
          name: ['apache2', 'php']
          state: present
      - name: Update git repository
        git:
          repo: https://github.com/mohsenSy/testphp.git
          dest: /var/www/html/test
          version: master
```

Save the previous code to a file called `main.yml` and create a new file beside it called `haproxy.cfg.j2`
with this content

```
global
	log /dev/log	local0
	log /dev/log	local1 notice
	chroot /var/lib/haproxy
	stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
	stats timeout 30s
	user haproxy
	group haproxy
	daemon

	# Default SSL material locations
	ca-base /etc/ssl/certs
	crt-base /etc/ssl/private

	# Default ciphers to use on SSL-enabled listening sockets.
	# For more information, see ciphers(1SSL). This list is from:
	#  https://hynek.me/articles/hardening-your-web-servers-ssl-ciphers/
	# An alternative list with additional directives can be obtained from
	#  https://mozilla.github.io/server-side-tls/ssl-config-generator/?server=haproxy
	ssl-default-bind-ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:RSA+AESGCM:RSA+AES:!aNULL:!MD5:!DSS
	ssl-default-bind-options no-sslv3

defaults
	log	global
	mode	http
	option	httplog
	option	dontlognull
  timeout connect 5000
  timeout client  50000
  timeout server  50000
	errorfile 400 /etc/haproxy/errors/400.http
	errorfile 403 /etc/haproxy/errors/403.http
	errorfile 408 /etc/haproxy/errors/408.http
	errorfile 500 /etc/haproxy/errors/500.http
	errorfile 502 /etc/haproxy/errors/502.http
	errorfile 503 /etc/haproxy/errors/503.http
	errorfile 504 /etc/haproxy/errors/504.http

frontend www_frontend
  bind 0.0.0.0:80
  default_backend www_backend

backend www_backend
  balance roundrobin
  {% raw %}
  {% for host in groups['web_nodes'] %}
  server web{{ loop.index }} {{ hostvars[host]['ansible_host'] }}:80 check
  {% endfor %}
  {% endraw %}
```

Now run this command
```
ansible-playbook main.yml
```

Then wait until it is done and ansible will install and configure haproxy and apache server on load balancer
and web servers the same way you did previously, all using a single command.

Time to explain what we just wrote:

## Playbook
The playbooks in ansible contains tasks that will be executed on servers as defined in the playbook, the line
`- hosts: web_lbs` executes `tasks` in this section on all servers in `web_lbs` group so if you need to add a new
load balancer or change the current one just edit ansible hosts file and run the playbook again, simple and easy :)

There are three tasks here the first one installs haproxy using `apt` ansible module, the second one copies haproxy
configuration file using the `template` module, this enables us to use variables and logic inside the template we will
explain about this in the next section. In this task we also have the `notify` option this is used to apply changes
to a server after something has changed to make sure any changes to haproxy configuration will trigger a restart
to haproxy to pick up the new changes.

The last task just starts haproxy and males sure it runs on boot.

After that we have tasks for `web_nodes` group which installs apache2 and php and also deploys our simple app
using the git module which takes three options here:
* `repo` defines the URL of the git repository we want to use this must be public or we have already setup SSH keys
  on the server to access the repository.
* `dest` here we define the path where the repository will be cloned to.
* `version` this defines the branch, commit or tag that will be checked out once the clone is done, this also updates
  the repository in case we run the playbook again.

## Ansible haproxy template file
In the playbook we used the template module with a file that will be evaluated and copied
to the server at the path specified in the task, this file `haproxy.cfg.j2` contains normal
text which can be found by default in haproxy configuration file with some additions at the end
these are the most important here

```
{% raw %}
{% for host in groups['web_nodes'] %}
server web{{ loop.index }} {{ hostvars[host]['ansible_host'] }}:80 check
{% endfor %}
{% endraw %}
```

We know that the load balancer will distribute traffic to backend servers since we created
a separate group for our web nodes we can use this group here to add all web servers to haproxy
configuration so in case if we add new servers to the web_nodes group they are added
automatically here after we re-run the ansible playbook.

Here we are using a `for` loop to create an entry for each host, `loop.index` to create
different unique names for each server and `hostvars` to retrieve the IP of the server from
ansible hosts, for this to work we must always specify the IP address using `ansible_host`
option which is a good practice.

Now let us revise how the previous extra tasks can be done now:
* To expand the web cluster to 10 servers we just need to add their IPs to the `web_nodes` hosts group
  and run ansible playbook again.
* To deploy the code to multiple servers we just need to run ansible playbook again without any changes
  and it will pull down the latest changes from master branch.
* To install PHP modules on the servers we just need to update our playbook and add task to install PHP modules
  and run ansible playbook again.

As you can see all tasks can now be done easily, quickly and without errors or the burden of connecting
to multiple servers and running commands, but wait a minute we still have some manual tasks such as:
* Creating new servers requires to access Digital Ocean web dashboard to create them and add their IPs to ansible.
* Deploying code to servers requires a manual re-run of ansible playbook and so is installing new PHP modules.

For the first one this can be automated with [terraform](https://www.terraform.io) which I will write an article about it later.

As for deploying new code or changes to servers this is easy using Continuous Integration software such as
[Gitlab CI](https://about.gitlab.com/product/continuous-integration/) which I will also explore in new articles later.


# Conclusion

In this article I tried to help you know the benefits of using infrastructure automation in your work using
ansible software which is considered one of the best automation tools in the industry, we tried to deploy a simple
web cluster without ansible with all the time it will take then we tried to do the same with ansible with less time
and execute tasks more easily such as expanding our cluster and deploying new code and changes to servers.

At the end we learned about terraform and gitlab CI and how they fit in the whole automation pipeline, we will
learn more about them in the future so stay tuned.

I hope you find the content useful for any comments or questions you can contact me
on my email address [mohsen47@hotmail.co.uk](mailto:mohsen47@hotmail.co.uk?subject=why-ansible)

Stay tuned for more articles. :) :)
