---
layout: post
title:  "Systemd Service tutorial"
date:   2018-08-19 16:50:00 +0300
categories: sysadmin
---

In this tutorial we will learn how create a service file to run a script as a service
using systemd, and write an ansible role to automate the process.

**Hint** This tutorial assumes you are familiar with ansible.

## Systemd Introduction and Service files
Here we will introduce you only to the very basics of systemd, to learn more about
systemd follow the lnks bellow.

Systemd is a suite of basic building blocks for a Linux system, it runs as PID 1
and is used to bootstrap all other services after boot and manage the life cycle
of Linux services.

Systemd services files can be found in one of these two locations `/lib/systemd/system`
or `/etc/systemd/system` where the second location takes precedence over the first one.

You can override a systemd service file by creating a directory called after the service
name and ends with `.d` e.g: if a service is called `test.service` the directory
must be called `test.service.d`, inside this directory we put files that end with `.conf`
and contain options that override the same options defined in the service file.

The basic structure of a service file is as follows:

```
[Unit]
Description=A test unit
[Service]
ExecStart=/usr/local/bin/test
Type=simple
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=test
```

The previous file in an INI file and contains the very basic structure of a systemd
unit file.

The first section `[Unit]` defines general information about the systemd unit.
The `Description` option describes the unit in general using few words.

The `[Service]` section defines the service it self and is very important for the
service operation.


`ExecStart` defines the absolute path to the binary ised to run the service.
`Type` defines the type of the service, here we care about only two types, `simple`
which means that the script's execution binary will run in foreground, the other type
is `forking` which means the script's execution binary will fork in background and
probably write the PID of the child process to a file that must be identified using
the `PIDFile` option to enable systemd to control the service.


`StandardOutput` and `StandardError` defines where to send the program's standard output
and error here it is sent to `syslog`.


The `SyslogIdentifier` is used to identify the service in syslog files, this will
be used later to direct output to a separate file for the service.

When this file is saved as `test.service` in `/etc/systemd/system` and started using
this command `sudo systemctl start test.service` the script found at `/usr/local/bin/test`
is executed as a background process and can be stopped using `sudo systemctl stop test.service`,
we can query its status using `sudo systemctl status test.service`.



For more information about systemd check [this tutorial](https://www.digitalocean.com/community/tutorials/understanding-systemd-units-and-unit-files) on digitalocean also check the systemd site [here](https://www.freedesktop.org/wiki/Software/systemd/).

## Send syslog output to a separate file

In the previous section we sent the output of our service to `syslog` which writes to
a the log file `/var/log/syslog` and writes the value of `SyslogIdentifier` to the log
line to identify that this output line came from this service.

We can tell syslog daemon to send the output from this service to a different file
by creating a new file called `test.conf` in this directory `/etc/rsyslog.d/`
and put the following line in it.
```
if $programname == 'test' then /var/log/test.log
```

Here the programname `test` is taken from `SyslogIdentifier` which is defined in the
service file.

Restart syslog for changes to take effect

```
sudo systemctl restart syslog
```

Now the ouyput of the service called `test` is redirected to `/var/log/test.log`.

## Use an ansible role to automate the previous tasks

Now we will use ansible to create a role that creates some service files, starts them
and possibly send their output to different files using syslog.

We will use variables to define the services we want to create and the files we want
to redirect logs to them.

Here is a sample ansible playbook to install the previous service on a server, setup syslog
for it and start it.

```yaml
---
  - hosts: server1
    become: true
    gather_facts: true

    vars:
      - systemd_services:
        - src: test
          dst: /usr/local/bin/test
          name: test
          upload: true
          type: simple
          description: test service
          log_file: /var/log/test.log
          started: True
        - dst: /usr/local/bin/dst
          name: dst
          type: forking
          pid_file: /var/run/dst.pid


    roles:
      - moshensy.systemd_service
```

In the previous playbook we are deploying the test service to a server called `server1`.


We used the `systemd_services` variable, which is an array of dictionaries and each
one defines a service, the service has the following options

`src` defines the location of the program file on the machine which is running ansible.

`dst` defines where the program will be saved on the server.

`upload` is a boolean variable which specifies if the file will be uploaded to the server.

`name` defines the name of the service.

`type` defines the service's type either `simple` or `forking`, if the type of the
service is `forking` you must define the `pid_file` option to tell systemd about
the file that will contain the PID of the child process to monitor.

`description` defines the service's description.

`log_file` defines the log file to be used for sending standard output and error to it.

`started` is a boolean which specifies if the service must be started or not.

## Conclusion
In this tutorial we learned how to create a service file in systemd, send its output
to syslog and then use syslog to send each service's output to a different file.

Finally we learned how to use an ansible role to automate all of the previous tasks.

I hope you enjoyed it, any feedback will be highly appreciated you can use the comment
section below or the ChatBot or email me directly at [mohsen47@hotmail.co.uk](mailto:mohsen47@hotmail.co.uk).
