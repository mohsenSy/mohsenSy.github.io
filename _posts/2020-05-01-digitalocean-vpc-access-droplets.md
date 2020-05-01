---
layout: post
title:  "Access Droplets in Digital Ocean VPC"
date:   2020-05-01 23:56:00 +0300
categories: sysadmin
summary: Learn how to access your droplets in Digital Ocean VPC, which are configured not to connect over the public network.
---

# Introduction
After the release of Digital Ocean VPC service, users would need a way to access
their droplets inside the VPC, especially those which are configured not to connect
over the public network and use another droplet as a gateway for the internet.

My previous tutorial found [here]({% post_url 2020-04-29-digitalocean-vpc-service %})
shows how to use the new service and also configure your droplets inside the VPC
to use another droplet for internet connectivity, and not to connect using its own
public IP address.

# What will we do?
In this tutorial we will:
* Learn how to use a Jump Host to access Digital Ocean droplets inside a VPC.
* Learn how to use the ProxyCommand to access Digital Ocean droplets inside a VPC.

# Using a Jump Host
A Jump Host (Jump Server) is a normal server that can be used as a SSH gateway to
other internal servers, it helps us to access servers that are not configured
to accept any connections on their public IP address.

Droplets within a single VPC are usually configured not to accept connections
on their public address and use another droplet to connect with the internet.

To follow along create two droplets with the smallest available size and put them
in the same VPC, choose one of them to be a jump host and configure the second
one to use the Jump Host to connect to the internet, this is described
[here]({% post_url 2020-04-29-digitalocean-vpc-service %}).

If you followed along you would have used the ProxyCommand by now, we will discover
this later here.

Now that our Jump Host is configured and our internal droplet is using it to connect
to the internet, let us learn how to use the Jump Host to connect to the droplet.

To connect using the Jump Host use this command:

```bash
ssh -J <username>@<public_ip_of_jump_host> <username>@<private_ip_of_droplet>
```

The usernames could be the same or could be different, you need to have access right
to both servers, the Jump Server and the Internal Server to be able to connect.

To save you from typing all these IP addresses and options, you can use the client
SSH configuration file located in `~/.ssh/config` as shown bellow

```
Host jump
        Hostname <public_ip_of_jump_host>
        user root

Host droplet
        Hostname <private_IP_of_droplet>
        User root
        ProxyJump jump
```

Now you can connect to the droplet using this simple command

```bash
ssh droplet
```

Jump Hosts are usually powered off and only powered on when needed to prevent
anyone from accessing the servers when no access is needed.

# Using the ProxyCommand
The proxy command is just like the Jump Host, it uses a server to connect
to the internal droplet, it differs in the configuration.

Use this command to connect to the droplet using ProxyCommand

```bash
ssh -o ProxyCommand="ssh -W %h:%p root@<public_IP_of_gateway_Droplet>" root@<private_IP_of_droplet>
```

Again to configure the ProxyCommand using client SSh configuration file, add
these liens to `~/.ssh/config`

```
Host jump
        Hostname <public_ip_of_jump_host>
        user root

Host droplet
        Hostname <private_ip_of_droplet>
        User root
        ProxyCommand ssh -q -W %h:%p jump
```

Then simply execute this command to connect

```bash
ssh droplet
```

Now we learned how to use the Jump Host and ProxyCommand to connect to Digital
Ocean droplets inside a VPC without a public IP address, however we may
want to access other services on these droplets such as a web server that is
running locally in the VPC, for this to be possible we need to use a VPN server.

We will learn how to use wireguard on Ubuntu 18.04 in a later tutorial.


# Conclusion

In this tutorial we learned how to use Jump Host and ProxyCommand to connect
to Digital Ocean droplets inside a VPC with no public IP, only with private IPs.

In the next tutorial we will learn how to use wireguard VPN server to access
droplets with private IPs from our own workstation.

I hope you find the content useful for any comments or questions you can contact me
on my email address
[mohsen47@hotmail.co.uk](mailto:mohsen47@hotmail.co.uk?subject=digitalocean-vpc-access)

Stay tuned for more articles. :) :)
