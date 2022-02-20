---
layout: post
title:  "Migrate a google CloudSQL instance using postgresql logical replication"
date:   2022-02-20 16:49:00 +0200
categories: sre
summary: Here we will migrate a postgresql instance running using google CloudSQL service from one project to another.
---

# Introduction
[CloudSQL](https://cloud.google.com/sql) is a google service that offers database as a service to google products, it allows
you to run [MySQL](https://cloud.google.com/sql/mysql), [PostgreSQL](https://cloud.google.com/sql/postgresql) or [SQL Server](https://cloud.google.com/sql/sqlserver)
databases without going through all the hassle of managing your own database cluster, it helps you to focus on the code and your applications
while google takes care of everything else for you.

Sometimes you might need to migrate your CloudSQL instances and google can help you with this, here are some scenarios:

* Between regions using the same network: You can use read replicas in this case, just create the replicas in the new region, wait
for data to be replicated and then promote the read replicas to be masters and use them as usual.
* Bteween regions to a different network: If you want to connect your new CloudSQl instances to a different network then you cannot use read
replicas for this, you need to use the [Database migration service](https://cloud.google.com/database-migration) to migrate data from your current instances to new instances in a new region and connected to the new network.
* Between projects: You might have a use case where databases must be migrated from one GCP project to another, in this case neither replicas nor the database
migration service can help you, these only work in the same GCP project, in this tutorial we will use the Logical Replication Service from PostgreSQL to migrate
data from one GCP project to another, the sample codes here contain only one GCP project but the concept is the same and can be applied to multiple projects.

In this tutorial we will:
* Learn about PostgreSQL logical replication
* Create a PostgreSQL CloudSQL instance using terraform.
* Setup logical replication between two PostgreSQL CloudSQL instances.

# PostgreSQL logical replication
PostgreSQL supports multiple replication method to ensure high availability and to have backups for data if one server is lost, two main
methods are **Physical Replication** and **Logical Replication**. All changes that happen on the data is written to a record called
Write Ahead Log (WAL), this record keeps all history of data changes, these changes can be used by other servers to keep a replica in sync
with the master and replicate data.

By default the changes written to WAL are low level changes, they relate to the PostgreSQL version and storage backend used and cannot be
used to replicate data with other versions of PostgreSQL, this is called **Physical Replication**.

The data written to WAL can be enriched to include data changes at a high level in the form of SQL statements, this is called **Logical Replication**,
this enables replicating data between multiple PostgreSQL versions, because data changes are described using a high level language and all
PostgreSQL versions support SQL queries, the same queries executed on master are sent to other nodes and executed there.

When configuring logical replication there are two types of nodes, the first one is the publisher nodes which send WAL changes to other nodes.
The second type is called subscriber nodes, these nodes receive WAL changes and replay them.

To create a publisher use this query

```
CREATE PUBLICATION <name> FOR TABLE <table name>;
CREATECREATE PUBLICATION <name> FOR ALL TABLES;
```

Subscribers are created using this command

```
CREATE SUBSCRIPTION <name> CONNECTION <conninfo> PUBLICATION <pub name>;
```

The `<conninfo>` is a string for connecting to the publisher it has the following synatx

```
host=<db host> port=<db port> dbname=<database name> user=<db user> password=<db password>
```

The user used for replication must have the `REPLICATION` role assigned to it, to create a user with this role use this command

```
CREATE USER replication_user WITH REPLICATION IN ROLE cloudsqlsuperuser LOGIN PASSWORD 'secret';
```

Or you can alter an existing user with this command

```
ALTER USER existing_user WITH REPLICATION;
```


In order to use Logical Replication we need first to set `wal_level` to logical on the publisher node, also set `max_replication_slots` to at least
the number of subscribers plus some extra for table synchronization, we also need to set `max_replication_slots` on the subscriber side too.

In CloudSQL this can be done by setting `cloudsql.logical_decoding` to `on` on publisher node and `cloudsql.enable_pglogical` on publisher and subscriber
nodes, more about this in the next sections.

For more information about PostgreSQL logical replication check [here](https://www.postgresql.org/docs/13/logical-replication.html)

# Create PostgreSQL instances with terraform
Now we need to create two PostgreSQL instances in google cloud using terraform, create a file called `provider.tf` with this content

```
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~>4.11.0"
    }
  }
}

provider "google" {
  project = <your project ID>
}

```

Run `terraform init` to initialize terraform.

Create a new file called `cloudsql.tf` with this content

```
resource "google_sql_database_instance" "publisher" {
  name             = "publisher-instance"
  database_version = "POSTGRES_13"
  region           = "europe-west3"

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled    = true
    }
    database_flags {
      name = "cloudsql.enable_pglogical"
      value = "on"
    }
    database_flags {
      name = "cloudsql.logical_decoding"
      value = "on"
    }

  }
  deletion_protection = "false"
}

resource "google_sql_database" "database_publisher" {
  name     = "test"
  instance = google_sql_database_instance.publisher.name
}

resource "random_password" "psql_admin_publisher" {
  length  = 16
  special = false
}

resource "google_sql_user" "admin_publisher" {
  instance = google_sql_database_instance.publisher.name
  name     = "test"
  password = random_password.psql_admin_publisher.result
}

resource "google_sql_database_instance" "subscriber" {
  name             = "subscriber-instance"
  database_version = "POSTGRES_13"
  region           = "europe-west3"

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled    = true
    }
    database_flags {
      name = "cloudsql.enable_pglogical"
      value = "on"
    }

  }
  deletion_protection = "false"
}

resource "google_sql_database" "database_subscriber" {
  name     = "test"
  instance = google_sql_database_instance.subscriber.name
}

resource "random_password" "psql_admin_subscriber" {
  length  = 16
  special = false
}

resource "google_sql_user" "admin_subscriber" {
  instance = google_sql_database_instance.subscriber.name
  name     = "test"
  password = random_password.psql_admin_subscriber.result
}

output "publisher_pass" {
  value = google_sql_user.admin_publisher.password
  sensitive = true
}

output "subscriber_pass" {
  value = google_sql_user.admin_subscriber.password
  sensitive = true

}

```

Now run `terraform init` again to install the random provider which is used to generate random passwords
for PostgreSQL users.

In this terraform code we are creating two CloudSQL instances in the same project with public IPs enabled, since
we have public IPs enabled the setup would be the same in two different projects, let us create the insatnces
with this command

```
terraform apply
```

Now you will have two instances, one is called `publisher-instance` and the other is `subscriber-instance`, first we need
to allow our public IP addresses to connect to the instances and also the outgoing IP address of `subscriber-instance` must
be able to connect to the publisher instance, get your public IP address with this command

```
curl http://ipv4.icanhazip.com
```

Add it to the authorized networks in both of your instances, they can be found [here](https://console.cloud.google.com/sql/instances) Make sure
to select the right project, get the outgoing IP address of subscrber instance and add it to the publisher instance.

Now we need to configure both instances.

# Configure publisher and subscriber for replication

You need to connect to the two instances first and grant the already created users permission to do replication, to get
the user's password use this command

```
terraform output publisher_pass
```
Then use this to connect to the instance
```
psql -U test -h34.159.180.168 -d test
ALTER USER test WITH REPLICATION;
```

Where `34.159.180.168` is the IP address of the instance, use the same with subscriber instance too.

Execute this query on both instances to enable logical replication

```
CREATE EXTENSION pglogical;
```

Create a test table on the publisher node and add some data to it

```
CREATE TABLE rep_test (id SERIAL PRIMARY KEY, data text);
INSERT INTO rep_test (data) VALUES ('apple'), ('banana'), ('cherry');
```

Also create the same table on subscriber node
```
CREATE TABLE rep_test (id SERIAL PRIMARY KEY, data text);
```
Replication only includes queries that modify data, it does not relicate the schema, this must be done manually.

Now create the publisher on the publisher node with this query

```
CREATE PUBLICATION pub FOR TABLE rep_test;
```

And create the subscriber on subscriber node with this command

```
CREATE SUBSCRIPTION sub CONNECTION 'host=34.159.180.168 port=5432 dbname=test user=test password=<test password>' PUBLICATION pub;
```
After this command the subscriber should start its initial sync and copy all data from publisher database
to the subscriber database, check that the table `rep_test` has data on subscriber with this command

```
test=> select * from rep_test;
 id |  data
----+--------
  1 | apple
  2 | banana
  3 | cherry
(3 rows)
```

Add new data on publisher and see how it is replicated to publisher, use this insert query on publisher

```
test=> INSERT INTO rep_test (data) VALUES ('sea');
INSERT 0 1
```

And check on subscriber now
```
test=> select * from rep_test;
 id |  data
----+--------
  1 | apple
  2 | banana
  3 | cherry
  4 | sea
(4 rows)
```

Now you have replication running between the two instances, you can at anytime shutdown your previous workload, migrate them to point
to the new instances and drop the subscription with this command

```
DROP SUBSCRIPTION sub;
```

This usually takes very little time which minimizes the downtime, this saves you from doing a full backup and then restore to the new instances
which can take a lot of time and causes unpleasant downtime for your workloads.

**HINTS:** You may have multiple tables, to replicate them all you can create a subscription for all of them using this command
```
CREATE PUBLICATION pub FOR ALL TABLES;
```
And to copy their schema use these two commands

```
pg_dump -d test --schema-only > test.sql
psql -d test < test.sql
```

This will dump only the tables' schema to a file called `test.sql` and restore it in the second instance.

# Conclusion
In this tutorial we learned how to use PostgreSQL logical replication to migrate CloudSQL
instances from one project to another, this can include other regions and other networks too
because we simply create the instances in the projects and setup replication between them, relying
only on PostgreSQL features without the need of special CloudSQL features.

I hope you find the content useful for any comments or questions you can contact me
on my email address
[mouhsen.ibrahim@gmail.com](mailto:mouhsen.ibrahim@gmail.com?subject=google-psql-logical-replication)

Stay tuned for more tutorials. :) :)
