---
layout: post
title:  "using Odoo CRM with Digital Ocean Managed Databases"
date:   2019-03-05 21:51:00 +0300
categories: sysadmin, cloud
summary: This tutorial describes how to install Odoo on Digital Ocean droplet and connect it to DO Managed Database.
---

In my previous [article]({% post_url 2019-02-26-My-thoughts-about-Digital-Ocean-managed-database %}) I talked about Digital Ocean Managed Database service and
explained how it can be used to create a scalable and highly available database
cluster that uses porstgresql, today I will explain how you can install Odoo
CRM and configure it to use a database cluster created by Digital Ocean Managed
Database service.

# What is Odoo?

Odoo is a ERP and CRM software written in Python from scratch, it offers a
complete solution for companies to manage their sales, inventory, web sites (
it has a website builder), marketing and many many more, it is trusted by
millions of users around the world.

For more information check their [website](https://www.odoo.com).

# Prerequisites
To complete this tutorial you are expected to have:
* A running postgresql cluster using DO managed database service, how to
  create one is described in my previous [article]({% post_url 2019-02-26-My-thoughts-about-Digital-Ocean-managed-database %}).
* A DO droplet with docker installed on it, you can use a one-click app
  or install docker as described [here](https://docs.docker.com/install/linux/docker-ce/ubuntu/).

# Create database user for Odoo
Before we start using Odoo we need to create a user for Odoo, we can do this using pgAdmin.

To create a user using pgAdmin, select your server from the left panel and right
click on `Login/Group Roles` and select `Create` --> `Login/Group role` as shown
in the following picture.

![]({{ site.url }}/assets/images/postgres-create-user-pgadmin.png)

In the `General` tab select a user name and optionally a comment to describe
what is the user used for, in the `Definition` tab select a password for the
user, in the `Privileges` tab check `Can login?` and `Create databases?` for the new user and click `Save`.

# Start Odoo
Now after the database user is ready we can start Odoo using docker and
docker-compose.

Login to your droplet and create a new directory called `odoo` then create
a new file called `docker-compose.yml` in the new directory with the following
content:

```
version: '3'
services:
  web:
    image: odoo:11.0
    ports:
      - "8069:8069/tcp"
      - "8072:8072/tcp"
    volumes:
      - web-data:/var/lib/odoo
    environment:
      - HOST=odoo-database-cluster-do-user-1548131-0.db.ondigitalocean.com
      - USER=odoo-user
      - PORT=25060
      - PASSWORD=asdfgh
volumes:
  web-data:
    driver: local
```

This is a docker-compose file, we specify one servcie called `web`, this service
uses `odoo:11.0` docker image and expose ports `8069` for web and `8072` for
live chat if used.

The service also uses a `web-data` volume so data is persisted among restarts
of the service, we finally define 4 important environment variables used
to connect to the database server these variables are:
* HOST: this variable contains the IP/host name of postgres server used by Odoo
  you can put your own value from the database page in DO managed database
  service.
* USER: The postgres user that Odoo will use when connecting to the database.
* PORT: the postgres port used again put your value from the database page in
  DO managed database service.
* PASSWORD: The postgres user password used when connecting.

We notice here that there is no option for the database name, odoo can be
used with multiple databases on the same server, so the database will be
created when accessing odoo web page.

Now start odoo with this command `docker-compose up -d`, make sure you are
in the same directory where `docker-compose.yml` file is located.

Odoo web page can be accessed at droplet_ip:8069, but however if you open it
now you will get an internal server error that is because the postgres database
created by DO does not include the default database called `postgres` and Odoo
somehow complains about the absence of this database so we need to create it first.

From pgAdmin interface right click on `Databases` and choose `Create` --> `Database`, enter the database name and click `Save`.

Now open the web url and fill the form to create a new database.

![]({{ site.url }}/assets/images/odoo-create-database.png)

After you fill the form and Click `Create database` you will be logged in
to your Odoo instance that uses postgres database from DO Managed Database
service.

# Conclusion
In this tutorial we learned how to start odoo using docker-compose and configure
it to use the database created using DO Managed Database service, now you can
use odoo as you require and ensure that your database can handle any load
you put on it using odoo and scale it as required thanks to DO services.

I hope you find the content useful for any comments or questions you can contact me
on my email address [mohsen47@hotmail.co.uk](mailto:mohsen47@hotmail.co.uk?subject=Odoo-Using-DO-Managed-Database)

Stay tuned for more tutorials. :) :)
