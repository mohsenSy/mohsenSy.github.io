---
layout: post
title:  "Access Odoo API using python client"
date:   2019-04-10 18:00:00 +0300
categories: development
summary: Here I will describe how to access and use Odoo API using the python client.
---

In a previous article I talked about installing Odoo on DO droplet using docker-compose
and configuring it to use DO Managed Database for postgresql data,
it can be found [here]({% post_url 2019-03-05-Odoo-CMS-With-Digital-Ocean-Managed-Database-Service %})

In this article I will talk more about Odoo data driven nature, how Odoo treats every thing
as data in its database and provides python model classes to access the data, I will
explain how Python can be used to access Odoo API and manipulate its data.

# Odoo Data Driven Model
Odoo uses a data driven model to describe all of its resources, users are just records
in its database so to create a new user a new record will be added to the database but
adding this record is done using a class in Odoo that represents a user in the
database, this class can use SQL queries to do its job and the users of the class do not
care about how the class is doing its job, it just gives them an API to create users.

This is called ORM (Object Relational Model) where class objects are automatically
mapped to records in the database and methods are used to create, delete, update
and select records from the database.

In Odoo you can think about any other resource in the same way, for example to create
a new invoice Odoo needs to add a new record to the invoices table and Odoo offers
a class to represent and manage these invoices, the same is true for sale orders,
chat messages, items in the warehouse, currencies etc...

In this tutorial we will learn how to use these classes through Odoo RPC API, we
will not be using the classes directly but we will use an API that can use
these classes internally to do the required tasks.

# Odoo API Quick start
Odoo uses RPC protocol for its API, so to use it we must use a RPC client and python
provides one in the xmlrpc package which is included in the standard library.

To test the API is working we need to prepare these four values:

1. url: The URL of Odoo installation.
2. db: The database used by Odoo.
3. username: The name of the user we want to authenticate as.
4. password: The password for the selected user.

## Test Version

We can start first by checking the server's version using this code:

```
from xmlrpc import client as xmlrpclib
common = xmlrpclib.ServerProxy('{}/xmlrpc/2/common'.format(url))
common.version()
```

Here we only used the URL without any authentication.

## Authentication
Authenticating to odoo using the API is very easy in the same way we got the version
we can authenticate to Odoo using database name, username and password, the following
code shows an example

```
from xmlrpc import client as xmlrpclib
common = xmlrpclib.ServerProxy('{}/xmlrpc/2/common'.format(url))
uid = common.authenticate(db, username, password, {})
```

Now the obtained `uid` can be used to send subsequent calls to Odoo API.

## Calling methods
We talked that Odoo is data driven so each interaction we do with the API is all
about reading, creating, deleting and modifying data we can use the `xmlrpc/2/object`
endpoint to do all of these tasks using the method called `execute_kw` this method
takes the following arguments:
* The database we want to operate on it.
* The userid we are using, this is the return value from authenticate method.
* The user's password.
* The model name, this is the data model we want to operate on it.
* The method we want to call against the model.
* A list of arguments passed by position.
* A dictionary of arguments passed by keyword (optional).

We will talk about the main methods here:
### Search
This method is used to read all data in the model that satisfies a condition or so called
domain filter, it could be empty which returns all data for the model, the domain filter
must be a list inside a list so to specify en ampty filter we use `[[]]`
The following code shows an example to search for all partners in Odoo

```
from xmlrpc import client as xmlrpclib
models = xmlrpclib.ServerProxy('{}/xmlrpc/2/object'.format(url))
partners = models.execute_kw(db, uid, password, 'res.partner', 'search', [[]])
print(partners)
```

If we want to retrieve only customer partners we use:

```
partners = models.execute_kw(db, uid, password, 'res.partner', 'search', [[['customer','=',True]]])
print(partners)
```

If we need to get all customers who are not companies we use

```
partners = models.execute_kw(db, uid, password, 'res.partner', 'search', [[['customer','=',True],['is_company', '=',False]]])
print(partners)
```

To learn more about domain filters check their docs [here](https://www.odoo.com/documentation/12.0/reference/orm.html#reference-orm-domains).

We notice that the return value is only the IDs of matched objects to get the actual objects
we use the `read` method
### Read
The read method is used to get actual objects using their IDs which are obtained usually
using the search method, we use it as following

```
partner_ids = models.execute_kw(db, uid, password, 'res.partner', 'search', [[['customer','=',True],['is_company', '=',False]]])
partners = models.execute_kw(db, uid, password, 'res.partner', 'read', [partner_ids])
print(partners)
```

We can limit the number of fields we get back in the response using the `fields`
keyword argument as follows

```
partner_ids = models.execute_kw(db, uid, password, 'res.partner', 'search', [[['customer','=',True],['is_company', '=',False]]])
partners = models.execute_kw(db, uid, password, 'res.partner', 'read', [partner_ids], {'fields': ['name', 'country_id', 'email', 'comment']})
print(partners)
```

But how can we get field names, read along for the answer

### fields get
The `fields_get` method is used to list the fields of a model as follows

```
fields = models.execute_kw(db, uid, password, 'res.partner', 'fields_get', [])
print(fields)
```

Here the response is a dictionary where each key is a field and each value is a dictionary
which contains information about the field such as type, string etc...

We can limit the amount of information in each field using `attributes` keyword as follows:

```
fields = models.execute_kw(db, uid, password, 'res.partner', 'fields_get', [], {'attributes': ['type', 'string']})
print(fields)
```

We usually need to search and read records at the same time so Odoo provides a method for that.

### Search and Read
The `search_read` method is used to search for data and read it at the same time using a single
call, it is used as follows:

```
partners = models.execute_kw(db, uid, password, 'res.partner', 'search_read', [[['customer','=',True],['is_company', '=',False]]], {'fields': ['name', 'country_id'], 'limit': 5})
print(partners)
```

To just count records we use the following code

```
count = models.execute_kw(db, uid, password, 'res.partner', 'search_count',[[]])
print(count)
```

Now enough of reading and searching it is time to create, update and delete records

### Create
To create a new record we use the `create` method as follows:

```
id = models.execute_kw(db, uid, password, 'res.partner', 'create', [{'name': 'Mouhsen Ibrahim'}])
print(id)
```

The previous code creates a new partner called "Mouhsen Ibrahim" all other fields in the
model are optional or have default values so we only need to specify a name for the new partner.
The method returns the id of the newly created record.

### Update
To update an existing record in the database we use the write method, it takes two arguments
a list of IDs to update and a dictionary of key/value pairs to be updated, the following code
updates the name of partner whose ID is `id` to "Sammy":

```
models.execute_kw(db, uid, password, 'res.partner', 'write', [[id],{'name': 'Sammy'}])
```

### Delete
A record can be deleted using the `unlink` method based on its ID, this code deletes
a partner with Id of `id`

```
models.execute_kw(db, uid, password, 'res.partner', 'unlink', [[id]])
```


# Conclusion
Here we learned about Odoo data driven model and how we can use RPC methods to read, search,
create, update and delete data in Odoo, these are the basics that we need to integrate Odoo
with other systems and to use it in our own scripts I will be working on a python library
that abstracts the Odoo API and provides classes and methods to manipulate data without
knowing about models and methods so stay tuned for more :)

I hope you find the content useful for any comments or questions you can contact me
on my email address [mohsen47@hotmail.co.uk](mailto:mohsen47@hotmail.co.uk?subject=Access-Odoo-API-Using-Python)

Stay tuned for more tutorials. :) :)
