---
layout: post
title:  "Deploying Odoo 14 using Digital Ocean App Platform"
date:   2020-11-10 23:22:00 +0300
categories: digitalocean
summary: Here I will show you how to deploy Odoo 14 using Digital Ocean App Platform.
---

# Introduction
Odoo 14 is the newest version of the popular Open Source CRM, the new version has
many new features and improvements in various fields, the full list of changes
can be found [here](https://www.odoo.com/odoo-14-release-notes).

Here we will learn how to use Digital Ocean App Platform along with Digital Ocean
Managed Database service to run Odoo 14 setup, without creating any droplets,
as the new App Platform service will help us here.


# What will we do?

In this tutorial we will:

* Create a postgresql managed database using Digital Ocean.
* Deploy Odoo 14 using App Platform and connect it with managed database.

## Create postgresql managed database
We have shown previously [here]({% post_url 2019-03-05-Odoo-CMS-With-Digital-Ocean-Managed-Database-Service %}) how to setup Odoo on Digital Ocean droplet
and link it with the managed database service, here we will use Digital Ocean
App Platform to run Odoo 14 instance and link it with a postgresql database.

To create the database Choose **Create** --> **Databases**.

For postgresql version select 10, keep the default plan, select your data center
a name for the cluster then click **Create a Database Cluster**

![]({{ site.url }}/assets/images/odoo14-create-db.jpg)

Wait for the cluster to finish creating.

Once the cluster is ready you need to add a new database to the cluster, go
to `Users and Databases` tab and enter `postgres` in database name then click
save.

Odoo needs this default database to exist before it can launch so we need to create
it here.

## Create a new App using App Platform
To create new apps in App Platform you need to push your code to a github
repository, I created a repository for Odoo 14 it can be found [here](https://github.com/mohsenSy/AppPlatformOdoo).

Fork this repository to your own account and then you can use later here to
create the Odoo 14 App.

Navigate [here](https://cloud.digitalocean.com/apps/) to create new Apps.

There are four steps to create the new app:

1- Choose your github repository, select the repository you just forked to
  your account.

2- Select your app's name, region and branch, make sure to enable `Autodeploy
  code changes` so any changes to your app's code will be deployed here.

3- Now you must add three environment variables used to connect to your database
  cluster, their names are HOST (Database Cluster public Host), USER (doadmin)
  and PASSWORD (use the password for doadmin user in the cluster's main page)
  DO NOT FORGET to encrypt the password so it is not echoed anywhere in the logs.
  Also change the HTTP Port to 8069.
  Lastly select add a database, choose an existing Database cluster.

4- Here you need to select the used plan, you can keep it at Basic plan.

Click on Launch Basic app and wait for the deploy to finish.

![]({{ site.url }}/assets/images/odoo14-step3.jpg)

Once the deploy is done you can open the new app using the provided link.

After you open Odoo's main page you need first to create a new database
for it, all database names for Odoo here must start with `odoo-`, I added
this to `odoo.conf` file in the github repository, you can change it using
`db_filter` option in that file.

Once the new database is created you can login to your Odoo setup now.

# Conclusion
In this short tutorial we have shown how to use App platform along with a managed
database to deploy Odoo 14 setup.

You can modify the Dockerfile and odoo.conf to change Odoo configuration
as needed.


I hope you find the content useful for any comments or questions you can contact me
on my email address
[mohsen47@hotmail.co.uk](mailto:mohsen47@hotmail.co.uk?subject=deploying-odoo14-using-digital-ocean-app-platform)

Stay tuned for more tutorials. :) :)
