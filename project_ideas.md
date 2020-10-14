---
layout: page
title: project Ideas
permalink: /university/project_ideas
---
Here I will post project ideas for graduation and semester projects in Information Engineering Faculty

# Projects I can supervise

* **Building a caching HTTP load balancer using C** The most famous HTTP load balancer ([haproxy](https://www.haproxy.com/)) does not include the ability
  to cache responses, here we want to create a HTTP proxy called proxyHttp for example and it should support many features
  including different load balancing algorithms, logging capabilities, high performance proxy and caching server. An example of caching load balancer is [varnish](https://varnish-cache.org/)  **difficulty 10/10**
* **Ansible deployments** This project is an improvement over ansible tool to enable it to deploy clusters of servers
  as a whole with minimal interaction from systems administrators. Here we will create something like this [tool](https://docs.ansible.com/ansible/latest/cli/ansible-pull.html) **difficulty 9/10**
* **Ansible tower alternative** This project aims to create a web interface to run ansible using it for visualizing
  the automation of the entire infrastructure using ansible tool. The result of this project must replace this [software](https://www.ansible.com/products/tower) **difficulty 8/10**
* **Load balanced web infrastructure using ansible** In this project we will create a web cluster which includes [haproxy](https://www.haproxy.com/) load balancer
  [varnish](https://varnish-cache.org/) cache server, [apache](https://httpd.apache.org/) and [nginx](https://www.nginx.com/) backend servers, these will be used to host a PHP website of choice with optionally a database cluster. [Ansible](https://www.ansible.com/) will be used for automation. **difficulty 8/10**
* **A complete software pipeline from development to production using jenkins** <a href="https://jenkins.io">jenkins</a> can be used
  to create a continuous integration and deployment pipeline to deploy code for any project from development to production environments.
  In this project we will show how it can be used to automate testing and deploying code to servers. **difficulty 7/10**
* **Asynchronous Messaging using RabbitMQ or Redis** In this project we will deploy a highly available, fault tolerant and scalable cluster
  using [RabbitMQ](https://www.rabbitmq.com/) and [Redis](https://redis.io/) and test how we can send and receive messages to them using a web interface and evaluate the performance of the two solutions. **difficulty 7/10**
* **A search cluster using Apache Solr** <a href="https://lucene.apache.org/solr/">Solr</a> is a popular, blazing fast and open source
  enterprise search platform, it is built on top of Apache Lucene, in this project we will deploy a search cluster using it
  and create a web interface to index data into Solr and search into indexed data, it is preferable to use Python for the web
  interface. **difficulty 7/10**
* **Chat application** In this project we will build a fast and scalable chat app using micro-services, this app will have the ability
  to create private and group chats with user profiles and additional features to help development teams communicate with each other. **difficulty 7/10** *not available*
* **Web interface for DPI** [Deep Packet Inspection](https://www.ntop.org/products/deep-packet-inspection/ndpi/) works on analyzing network packets and extracting information
from them, in this project we will build a python module for inspecting some common application protocol packets such as HTTP, DNS, etc... and API to use the module and a web
interface that calls the API, at the end we will have a web application for reading pcap files and displaying them in a web browser interface. *not available* **difficulty 7/10**
* **Performance evaluation of Database clusters and load balancers** A previous team (<a href="https://www.facebook.com/aalaa.elbishiny.1">Aalaa Albesheny</a> and
  <a href="https://www.facebook.com/Ibrahim.Alfeel">Ibrahim M Alfeel</a> and <a href="https://www.facebook.com/taimaaib">
  Taimaa Ibraheem</a>) did a project about the deployment of database clusters using NDB and percona cluster
  with haproxy and proxysql load balancer, here in this project we will use their work after getting their permission and evaluate
  the performance of read versus write operations using NDB and percona with proxysql and haproxy load balancers. **difficulty 6/10**
* **DCOS** [DCOS](https://dcos.io/) is a distributed cloud operating system that can be used to deploy software on multiple machines and manage them from a single
  interface it uses Apache Mesos as low level backend for scheduling work loads on servers. **difficulty 6/10**
* **Storage Clusters** This project we will deploy two types of storage clusters, [GlusterFS](https://www.gluster.org/) and [LizardFS](https://lizardfs.com/) and compare them.*not available*
**difficulty 6/10**

# Projects I cannot supervise
* **Paralyzing algorithms with MapReduce** MapReduce is a distributed computing framework which allows to divide applications
  into tasks and sending these tasks to multiple machines and getting results from all of them, here an algorithm
  will be selected and implemented using MapReduce. **difficulty 9/10**
* **Video Game** A previous project by (<a href="https://www.facebook.com/ali.ratel">Ali Ratel</a>, <a href="https://www.facebook.com/hasansan88">
  Hasan Alkhayer</a> and <a href="https://www.facebook.com/emad.king.5015"> Emad Eslamboly</a>) created a video game using Unity Game Engine,
  we can get their permission to use the code and improve the game. **difficulty unkown**
* **Image Search Engine** A previous project by (<a href="https://www.facebook.com/adam.oudaimah">
  Adam Oudaimah</a>, <a href="https://www.facebook.com/profile.php?id=100010620545280">
  أكرم قاسم</a> and <a href="https://www.facebook.com/profile.php?id=100010602547873">Mohammad Ali</a>), created a ML model
  for captioning images, in this project we will build a web application that crawls images on the web, convert them
  to text and store them in a database then make it searchable using the web interface. **difficulty 9/10**
* **IRP (Intelligent Routing Platform)** In this project we can use <a href="https://www.noction.com/irp-lite">IRP Lite</a> to discover how intelligent
  routing can work. **difficulty unkown**
