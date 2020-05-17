---
layout: post
title:  "Python Library to access Digital Ocean API"
date:   2020-05-17 13:25:00 +0300
categories: sysadmin
summary: Here I present the first version of my python library to access and use Digital Ocean API.
---

# Introduction
According to Digital Ocean website there are only two official API clients
the first one is written in go and can be found [here](https://github.com/digitalocean/godo)
and the other one is written in ruby and can be found [here](https://github.com/digitalocean/droplet_kit),
however for python there are only three libraries as can be seen [here](https://developers.digitalocean.com/libraries/),
and none of these libraries is complete and supports all kinds of Digital Ocean
resources, so I decided to work on my own Digital Ocean client using python
and build it to be easily extensible to support all existing Digital Ocean
resources and easily add support to new resources as they are added.

# What will we do?
In this article you will:
* Learn about my motivation to create the python client and its overall structure.
* Learn how to add new resources to the library easily.
* Manage some Digital Ocean resources using the library.

# Library structure
I wanted to create this library for the following reasons:
* Learn about Digital Ocean API and how it can be used to manage Digital
  Ocean resources, this will help me understand Digital Ocean infrastructure
  and use this understanding in my own projects.
* The available Python libraries for Digital Ocean API are limited in their
  scope and support.
* Apply my knowledge in Python using a real project, this will help me to
  improve my Python and software skills.

There are modules for each Digital Ocean resource type, one for droplets,
another for images, ssh keys, sizes, regions etc...

The most important modules in the library are:
* `common` module which contains a function that is used when processing response
from Digital Ocean, it takes dictionary keys and convert their values to objects if
applicable, it also contains a class that can be used with the `json` builtin module
to serialize objects and save them to a file.

* `auth` module, this one has the `Auth` class which holds authentication information
used to access the API and the base URL.

* `resource` module, this is the most important module, it contains
the `Resource` class that is the parent class to all Digital Ocean
resources in this library, most of the logic happens in this class
and thanks to its design we can easily add new resources to the API and
support them. We will talk a little bit about this class because it is very important.

This class has two required attributes, the first is called `resource` and
it holds the class object of a class that inherits from `Resource`,
and the second is called `auth`, it hold authentication information.

To clarify the previous line look at this code:

```python
class Resource(object):
  def __init__(self, resource):
    self.resource = resource

class Droplet(Resource):
  def __init__(self):
    super().__init__(Droplet)
```

In the constructor of class `Droplet` we pass the class itself to the
constructor of its parent class that is `Resource`, and here we save
this class in an instance attribute called `resource`, this means that
this object now manages a `Droplet`, it will use special class attributes
found in `Droplet` to do the management, we will talk more about them later.

The `auth` attribute can be set using the `authenticate` method of the library,
this method takes the access token as an argument, if no token is provided
it tries to use the value for the `DO_TOKEN` environment variable and
if it is not found then it raises an exception.

`auth` is a class attribute shared by all objects, where resource
is an instance attribute, specific to a single object.

This class also has methods to make `GET`, `POST`, `PUT` and `DELETE`
HTTP requests, it also has methods to return a list of resource instances,
create new instances and also list actions for them.

It has a `json` method that returns a JSON representation of the object.

# Python Magic Methods
In this library I used two python magic methods to make using (consuming) it
and also developing the library super easy, first let us learn about Python
magic methods.

Python magic methods are like normal python methods but they are not
called directly by python developers, they are called automatically called
by the Python interpreter behind the scenes when specific conditions
are met or in specific situations, for example the `__init__` magic
method is called when a new object of a class is created, it is used
to initialize object attributes with values.

Here is a small list of python magic methods:

* `__eq__`: This method is called when we compare two objects using `==` operator.
* `__ne__`: This method is called when we compare two objects using `!=` operator.
* `__getitem__`: This one is called when we try to use an index on the
  object like this: `x[2]`
* `__del__`: This method is called when we delete the object: `del x`
* `__call__`: This method is called when we try to call the object
  as a function: `x()`.

There are many more magic methods, you can learn more about them [here](https://rszalski.github.io/magicmethods/).

Now back to my library, in this library I used two particular magic methods
to help me make the library easier to use and develop.

These two methods are: `__getattribute__` and `__setattr__`.

## __getattribute__
This method is called every time we try to access an attribute of an object
like this `obj.x` this calls `obj.__getattribute__("x")` behind the scenes,
I used this to allow the library to fetch from Digital Ocean API behind
the scenes without the user explicitly calling an API endpoint or even
using a method that will call the API endpoint.

This means that when we try to access an attribute of an object that represents
a Digital Ocean resource, the library first makes sure if the attribute's value
was fetched previously from the API or not, then it makes the decision to make
an API call and return the result or return it immediately, of course the
library fetches the entire resource from Digital Ocean and not only the
attribute requested.

Here is the code for `__getattribute__` method in `Resource` class

```python
    if attr == "resource":
        return object.__getattribute__(self, attr)
    resource = object.__getattribute__(self, "resource")
    static_attrs = resource._static_attrs
    dynamic_attrs = resource._dynamic_attrs
    fetch_attrs = resource._fetch_attrs
    action_attrs = resource._action_attrs
    if attr in static_attrs or attr in dynamic_attrs or attr in fetch_attrs:
        return self.__fetch(attr)
    if attr in action_attrs:
        return lambda **kwargs : self.action(type=attr, **kwargs)
    return object.__getattribute__(self, attr)
```

Before I describe what this code does, I will give you a **warning** so
you do not make my mistake again, when implementing the `__getattribute__`
method for your own class you could easily fall in an infinite loop
that will hit your recursion limit and cause your code to fail, because
every time you try to access an attribute of your object inside the
`__getattribute__` method, the method will be called again, so pay attention
and use the `object` class, this one is the parent of all python objects,
here is an example of using it and how it will solve our recursion limit issue.

Look at this code and compare these two lines:

```python
print(obj.x)
print(object.__getattribute__(obj, "x"))
```

These two lines will print the same result, notice that `x` in the second
line is passed as a string.

The first line calls the `__getattribute__` on `obj` and returns the result,
however the second one calls the `__getattribute__` on object, and passes
to it the `obj` object with the name of attribute as a string, so here
the `__getattribute__` of `obj` is not called, with this way we can avoid
calling `__getattribute__` again when implementing the method in our classes.

Now let us get back to the code.

The first three lines make sure we can easily get the value of `resource`
attribute, this is very important because the rest of the code depends
on it.

Remember that the value of `resource` attribute is a class that inherits
from our `Resource` class.

The next four lines get values for four class attributes of `resource`
these are `_fetch_attrs`, `_static_attrs`, `_dynamic_attrs` and `_action_attrs`.

What are these lists?

* `_fetch_attrs`: This list contains names of Digital Ocean attributes for
  this resource that can be used to fetch new instances of the resource, for
  example we can fetch a droplet by its ID, we can fetch an image by its
  slug or ID, we can fetch a Floating IP by its IP value and so on, when
  these attributes change value then we need to fetch the object again
  from Digital Ocean, more on this later.
* `_static_attrs`: This list contain names of Digital Ocean attributes
  that are set automatically by Digital Ocean and cannot be changed
  directly, for example: timestamps, we cannot change these.
* `_dynamic_attrs`: This list contains names of Digital Ocean attributes
  that can be used when creating a new instance of a resource or updated
  for a resource.
* `_action_attrs`: This list contains names of actions that can be called
  on the object, some Digital Ocean resources have actions associated
  with them, these are written here and called when requested as we will
  see shortly.

Now after these lists are ready we have two if statements, the first one
checks if the requested attribute is in one of these lists `_fetch_attrs`,
`_static_attrs` or `_dynamic_attrs` we return the value of calling
the method `__fetch` with the attribute's name as a parameter, this
method first checks if we previously fetched this resource using `__fetched`
attribute, if yes then it just returns the value of the attribute and if
not it calls the API request to fetch the resource from Digital Ocean, it
checks whether we have an attribute that changed previously or not,
and fetch based on its new value, if no attribute was changed the ID of the
resource is used, the name of ID attribute is stored in `_id_attr` attribute.

The second if statement is used for actions, it returns a lambda function
that accepts any number of key word arguments and then calls the action
method using the right value for action type and all the used key word
arguments.

Lastly if the attribute is not within any of these lists, its value is just
returned with help from `object`, this could throw an error.

## __setattr__
The `__setattr__` method is called when we set a value for an attribute, like
in the following code:

```python
obj.x = 2
```

This translates to

```python
obj.__setattr__("x", 2)
```

Which sets the value of `2` to the attribute called `"x"`.

Here is the code for `__setattr__` method in class `Resource`

```python
    if attr == "resource":
        object.__setattr__(self, attr, value)
    resource = object.__getattribute__(self, "resource")
    static_attrs = resource._static_attrs
    dynamic_attrs = resource._dynamic_attrs
    fetch_attrs = resource._fetch_attrs
    if attr in fetch_attrs:
        self.__dict__["__changed"] = attr
        self.__dict__["__fetched"] = False
    if attr in static_attrs:
        return
    self.__dict__[attr] = value
```

First we process the case when we set the `resource` attribute, then we get
the value for this attribute and use it later.

We also store values for `_static_attrs`, `_fetch_attrs` and `_dynamic_attrs`
in local lists, then we do two checks.

If the attribute is in `_fetch_attrs` list we set `__fetched` to False, and
set `__changed` to the attribute name, these two attributes help the `__fetch`
method to check if the resource was fetched or not or if an attribute value
was changed since the last time we fetched it.

We also note that if the value for the attribute is in `_static_attrs` list
we simply return without doing anything to prevent users from changing values
of static attributes, these values are set by Digital Ocean and cannot be changed
at all or directly.

With these two magic methods we are able to write classes for Digital Ocean
resources easily by filling values for the previous lists and also some other
attributes that we will discover in the next section.

# The structure of classes that represent Digital Ocean resources
As we stated previously, each Digital Ocean resource has a class that inherits
from the class `Resource` and defines values for some attributes, which helps
the `Resource` class to manage the resource in Digital Ocean.

As an example we will use the class that represents Digital Ocean droplets,
check the partial code for this class bellow

```python
class Droplet(Resource):
    _url = "droplets"
    _plural = "droplets"
    _single = "droplet"
    _fetch_attrs = ["id", "name"]
    _static_attrs = ["memory", "vcpus", "disk", "locked", "created_at", "status", "backup_ids", "snapshot_ids", "features", "region", "image", "size", "size_slug", "networks", "kernel", "next_backup_window", "volume_ids"]
    _dynamic_attrs = ["name", "region", "size", "image", "ssh_keys", "backups", "ipv6", "private_networking", "user_data", "monitoring", "volumes", "tags"]
    _action_attrs = ["enable_backups", "disable_backups", "power_cycle", "reboot", "shutdown", "power_off", "power_on", "restore", "password_reset", "resize", "rebuild", "rename", "change_kernel", "enable_ipv6", "enable_private_networking", "snapshot"]
    _delete_attr = "id"
    _update_attr = ""
    _action_attr = "id"
    _id_attr = "id"
    _resource_type = "droplet"
    def __init__(self, data=None):
        super().__init__(Droplet)
        if data is not None:
            self._update({self._single: data})
    @classmethod
    def list(cls, **kwargs):
        droplets = super().list(**kwargs)
        return [cls(x) for x in droplets]
```
With these 21 lines of code, my droplet class is functional, and can be
used to list, create, update and delete droplets and also call of their actions,
the real `Droplet` class has some extra methods which are specific for a droplet
and are not shared with other Digital Ocean resources such as `listSnapshots` to
list all droplet snapshots, `getPublicIP` to get the public IP v4 of the droplet
and many more.

Let us look at the class attributes that start with `_` in this class:

* _url: This tells the URL that is used when accessing droplet data in Digital Ocean.
* _single: This is the dictionary key used in Digital Ocean response when fetching
  a single droplet.
* _plural: This is the dictionary key used in Digital Ocean response when fetching
  multiple droplets.
* _fetch_attrs, _static_attrs, _dynamic_attrs, _action_attrs were described
  previously.
* _delete_attr: The name of attribute used when sending a `DELETE` request to
  Digital Ocean, the value of this attribute is added to the end of the url.
* _update_attr: The name of attribute used when sending a `PUT` request to
  Digital Ocean, the value of this attribute is added to the end of the url.
* _action_attr: The name of attribute used when calling an action, the value of this
  attribute is added to the end of the url.
* _id_attr: The name of the attribute used as an ID for the resource.
* _resource_type: The type of resource as a string, this value is used with tags.

The constructor here calls the parent constructor and passes to it the `Droplet`
class, the `list` method here calls the `list` method in parent class and then
convert the dictionaries returned to `Droplet` objects.

# How to use the library

To install the library use this command

```bash
pip3 install https://github.com/mohsenSy/dopyapi.git
```

I will only show how to create and list droplets here, for more tutorials
and complete API reference follow this link.

First you need to get an access token to be able to access the API, open
this [url](https://cloud.digitalocean.com/account/api/tokens) in your browser
and create a new access token, save the value somewhere safe because you cannot
see it later then execute this command on terminal

```bash
export DO_TOKEN=<access_token>
```

This command stores the access token in an environment variable to make this variable
available all the time add the command to your `~/.bashrc` file.

```python
  import dopyapi as do
  do.authenticate()
  droplets = do.Droplet.list()
  for droplet in droplets:
    print(droplet)
  droplet_data = {
      "name": "d1",
      "image": do.images.ubuntu,
      "size": do.sizes.tiny,
      "region": "ams3",
      "ssh_keys": do.SSHKey.list()
  }
  droplet = do.Droplet()
  droplet.create(**droplet_data)
  print(droplet.getPublicIP())
  print(f"droplet with id {droplet.id} was created at {droplet.created_at}.")
```

In the previous code we first import the `dopyapi` library and rename it to `do`,
actually I was using the name `do` in early stage development but I found it could
not be suitable for a library name so I am used to call the library just `do`.

The function `do.authenticate()` put authentication information in the class
`Resource`, here it takes the token from the environment variable, because
we did not pass the value as a parameter.

We are using the classmethod `list` to retrieve a list of all droplets and print
them.

After that we prepare the values for required attributes when creating a new
droplet, these are the name of droplet, its image, its size and region, we also
provide a value for `ssh_keys` which is optional but we use it here, we are
adding all of our SSH keys to the droplet.

Notice we used some constants defined in the `images` and `sizes` modules, these
help us to use images and sizes without memorizing their actual names.

After that we create a new object of droplet class, then call `create` on it,
this will make an API request to create the droplet, after that we use `getPublicIP`
to print the IP address for the droplet, this method will wait until the droplet
is ready then return.

Lastly we try to print the droplet's ID and the time of droplet creation.

# Conclusion
In this article I presented my own work on a Python library to access
Digital Ocean API, it can be used in your own projects if you need
to integrate Digital Ocean services in your applications, I will work
to improve this library and add support to all Digital Ocean resources
before the final public release of the library.

Please try using it and report any issues [here](https://github.com/mohsenSy/dopyapi/issues/new), I will happily work to solve your issues.

For full documentation check [here](https://dopyapi.readthedocs.io/en/latest/)

I hope you find the content useful for any comments or questions you can contact me on my email address
[mohsen47@hotmail.co.uk](mailto:mohsen47@hotmail.co.uk?subject=python-library-digital-ocean-api)

Stay tuned for more articles. :) :)
