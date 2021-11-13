---
layout: post
title:  "Use terraform module to create Digital Ocean databases"
date:   2021-11-13 16:20:00 +0200
categories: SRE
summary: Learn how to use Terraform modules to create Database clusters in Digital Ocean
---

# Introduction
Digital Ocean offers Managed Database Services which allow you to easily create new database clusters and use them
quickly without needing the effort to set them up or to manage the availability and scaling of the clusters, you
can create the clusters using the Digital Ocean cloud console or by writing terraform code that will manage
the creation, update and deletion of the clusters for you.

In this tutorial you will learn how to use my first published terraform module to manage database clusters in
Digital Ocean, you can find the module in terraform module registry [here](https://registry.terraform.io/modules/mohsenSy/db/digitalocean/latest)

# What will you do?

In this tutorial you will:

* Install terraform.
* Create a Digital Ocean database cluster using terraform module.
* Learn how to use yaml configuration files to supply arguments for the terraform module

# Terraform
Modern infrastructure is managed using Infrastructure as Code Tools, [terraform](https://terraform.io) is one of
the most famous tools in this domain, it can be used to describe any kind of infrastructure using scripts and
then it will modify your existing infrastructure to match the state defined in terraform.

You can install terraform from this [page](https://www.terraform.io/downloads.html) accorsing to your OS.

If you are running Linux use these commands

```bash
wget https://releases.hashicorp.com/terraform/1.0.11/terraform_1.0.11_linux_amd64.zip
unzip terraform_1.0.11_linux_amd64.zip
sudo install -m 755 terraform /usr/local/bin
rm terraform_1.0.11_linux_amd64.zip terraform
```

To make sure terraform is installed use this command

```bash
terraform version
```

It will print the version of terraform

```
Terraform v1.0.11
```

# Terraform module
Terraform modules allow you to group some resources together and manage them as a whole, this allows SREs
to create modules that can be used by developers to safely create the infrastructure they need for their
services and applications, to learn more about terraform modules check [docs here](https://www.terraform.io/docs/language/modules/index.html)

We will start by writing some terraform code to define the providers that we need and then use the
module to create a MySQL database cluster, create a new directory for your code with this command

```
mkdir ~/do-db
cd ~/do-db
```

Create a new file called `provider.tf` with this code

```
terraform {
  required_version = ">= 1.0.11"
  required_providers {
    digitalocean = {
        source = "digitalocean/digitalocean"
        version = ">= 2.16.0"
    }
  }
}

provider "digitalocean" {}

```

If you get errors about your terrafrom version make sure you are using the terraform binary that
you installed in `/usr/local/bin`, the command `type -a terraform` can help you to know which terraform
binary you are actually using, you can also use this command `alias tf=/usr/local/bin/terraform` to
force using the right terraform version by using the alias `tf` instead of the command `terraform`

Create a new file called `dbs.tf` with this content

```
module "db" {
  source  = "mohsenSy/db/digitalocean"
  version = "0.2.0"

  name = "sql-cluster"
  size = "db-s-1vcpu-1gb"
  engine = "mysql"
  db_version = "8"
  node_count = 1
  region = "fra1"

  users = ["sami", "mouhsen"]
  tags = ["sql", "fra1"]
  firewall_rules = [
      {
          type = "tag"
          value = "backend"
      }
  ]
}

output "host" {
  value = module.db.host
}

output "passwords" {
  sensitive = true
  value = module.db.passwords
}
```

Here we define a module called `db` that uses the terraform module for Digital Ocean databases as a source
and we are using version `0.2.0` of the module, the module has 6 required arguments:

* name: The name we want to give to the database cluster
* size: The size of database cluster nodes, here we choose a small size of `1 vCPU` and `1 GB` of RAM.
* engine: Here we specify the type of database cluster we will create, there are 4 types until the time of writing
  this tutorial, they are: `mysql`, `pg`, `mongodb` and `redis`.
* db_version: the version of mysql that we want to use, only version `8` is available.
* node_count: The number of nodes that will be used the node pool.
* region: Here we specify the region where the cluster will be created. We are using Frankfurt/Germany here.

There are additional attributes here such as:
* users: Here we specify the database users to create as a list.
* tags: We put here the tags that we want to assign to the cluster.
* firewall_rules: Here we specify the firewall rules to be applied to the cluster, in this case
  we are applying a single rule to allow connections from any resource with the tag of `backend`.

After defining the module we are defining two outputs here, the first is called `host` and it holds
the host name for the database cluster which we can use for connecting to the cluster, also
we have another output called `passwords` which will hold the passords assigned to the users.

now we can apply terraform using these commands

```
terraform init
terraform apply
```

It will take few minutes to finish applying terraform.

After it is done applying you will get an output like this

```
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

host = sql-cluster-do-user-1548131-0.b.db.ondigitalocean.com
passwords = <sensitive>
```

And you will find a new Database Cluster in your Digital Ocean cloud console with the users created and the firewall
rules applied.

You can do the same with other clusters just change the `engine` argument and supply the needed arguments to the module.

When creating a pg cluster you can define replicas and pools like this

```
replicas = [
  {
    name = "replicas1"
    size = "db-s-1vcpu-1gb"
    region = "fra1"

    tags = []
    private_network_id = ""
  }
]

pools = [
  {
    name = "pool1"
    mode = "transaction"
    size = "db-s-1vcpu-1gb"
    db_name = "db1"
    user = "user1"
  }
]
```

If you don't specify size and region for replicas then the same size and region are used from the cluster.

When creating a redis cluster you can specify the eviction policy using the `eviction_polciy` argument.

# Using a config file to define the clusters
When you are writing a service that will listen to a port for connections, you use an environment variable to define
the port so you can easily change the listening port without changing and recompiling the code, the same thing is
here, we need to be able to change the database clusters that we will create without touching the code files.

To achieve this we will modify our code to read clusters' information from a YAML configuration file and then apply
the code, with this method we can add new clusters, remove and change existing ones by only modifying the
configuration files.

Now create a YAML file called `data.yaml` with this content

```
---
do_clusters:
  - name: pg-sql
    engine: pg
    size: db-s-1vcpu-1gb
    node_count: 1
    region: fra1
    db_version: 11
    tags:
    - sql
    users:
    - sami
    - mouhsen
  - name: mongo
    engine: mongodb
    size: db-s-1vcpu-1gb
    node_count: 1
    region: fra1
    db_version: 4
```

Here we are defining two clusters one is called `pg-sql` and the other is called `mongo`, we gave values to all the required attributes here.

Now we need another yaml file to define default values for the non-required attributes, create a file called `default.yaml` with this content

```
---
eviction_policy: allkeys_lru
firewall_rules: []
maintenance_window:
  day: tuesday
  hour: 01:00:00
pools: []
replicas: []
sql_mode: ANSI,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION,NO_ZERO_DATE,NO_ZERO_IN_DATE,STRICT_ALL_TABLES
tags: []
users: []
private_network_uuid: ""
```

Here we used default values for every non-required attribute in the module, we will learn the importance of this very soon.

Now back to the code, write this locals section at the start of the `dbs.tf` file

```
locals {
  config = yamldecode(file("./data.yaml"))
  default_config = yamldecode(file("./default.yaml"))

  db_names = [for db in local.config.do_clusters : db.name]
  dbs_ = [for db in local.config.do_clusters : merge(local.default_config, db)]
  dbs = zipmap(local.db_names, local.dbs_)
}
```

Here is where the magic happens, first we read the data files and decode them, secondly we create
a tuple of the database names, and then we create a tuple of the objects defining every database after
merging the default config with the database config so we are sure that the objects that we get have
a value for every attribute needed for the module and lastly we zip the names with the objects
to get a new object that can be used in the for_each meta argument where clusters' names are the keys
and the values are the clusters' objects.

Modify the module defenition to look like this

```
module "dbs" {
  source  = "mohsenSy/db/digitalocean"
  version = "0.2.0"

  for_each = local.dbs

  name = each.value.name
  size = each.value.size
  engine = each.value.engine
  db_version = each.value.db_version
  node_count = each.value.node_count
  region = each.value.region

  users = each.value.users
  tags = each.value.tags
  firewall_rules = each.value.firewall_rules
  replicas = each.value.replicas
  pools = each.value.pools
  eviction_policy = each.value.eviction_policy
  private_network_uuid = each.value.private_network_uuid
  sql_mode = each.value.sql_mode
  maintenance_window = each.value.maintenance_window
}
```

As you can see here, we are specifying a value for every argument, this is thanks to merging
the objects in `data.yaml` with the values in `default.yaml`, which guarantees that every
`each.value` will have a value for every argument.

You need now to fix the ouputs a bit, something like this

```
output "sql_host" {
  value = module.dbs["pg-sql"].host
}

output "sql_passwords" {
  sensitive = true
  value = module.dbs["pg-sql"].passwords
}
```

If you try to apply now it will create two database clusters according to your config

```
terraform init
terraform apply
```

After applying you will have two database clusters in your Digital Ocean account.

# Conclusion

In this tutorial we learned how to use the Digital Ocean database module found [here](https://registry.terraform.io/modules/mohsenSy/db/digitalocean/latest)
to manage different kinds of database clusters in Digital Ocean, we also learned how to use yaml configuration files to supply
config to the database module so we can focus on the configuration without changing the code.

I hope you find the content useful for any comments or questions you can contact me
on my email address
[mouhsen.ibrahim@gmail.com](mailto:mouhsen.ibrahim@gmail.com?subject=digitalocean-database-module)

Stay tuned for more tutorials. :) :)
