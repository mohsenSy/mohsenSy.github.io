---
author:
  name: mouhsen_ibrahim
  email: mohsen47@hotmail.co.uk
description: 'Using Nginx as a reverse proxy'
keywords: 'nginx,proxy'
license: '[CC BY-ND 4.0](https://creativecommons.org/licenses/by-nd/4.0)'
published: ''
title: 'Nginx reverse proxy'
contributor:
  name: Mouhsen Ibrahim
  link: https://github.com/mohsenSy
  external_resources:
- '[Nginx Documentation](https://nginx.org/en/docs)'
- '[Reverse Proxy Documentation](https://www.nginx.com/resources/admin-guide/reverse-proxy/)'
---

## Introduction
[Nginx](https://www.nginx.org) is a HTTP and reverse proxy server, written by [Igor Sysoev](http://sysoev.ru/en/)
and is used by many high traffic Russian websites, using Nginx as a reverse proxy is a simple task which we
will cover in this guide but before that we will take a look at reverse proxies to get an idea about what
are they used for?

## What is a reverse proxy?
A [reverse proxy](https://en.wikipedia.org/wiki/Reverse_proxy) is a type of proxy server which retrieves content
from backend servers on behalf of the client, the backend server reveives connections only from the reverse proxy
and not from the client, it can be used to hide the identity of backend servers, as a application firewall to
force authentication before accessing backend servers, SSL termination at the proxy level, caching content and many other uses.

## Before You Begin
1. Complete the [Getting Started](https://www.linode.com/docs/getting-started) guide.
2. Follow the [Secure Your Server](https://www.linode.com/docs/security/securing-your-server/) guide to create
   a standard user account, harden SSH access and remove unnecessary network services; this guide will use
   `sudo` whereever possible.
3. Log in to your Linode via SSH and check for updates using `apt-get` package manager.

  `sudo apt-get update && sudo apt-get upgrade -y`

4. If you are a beginner at using Nginx you can check this [tutorial](/docs/web-servers/nginx/how-to-configure-nginx).


## Install Nginx
To install Nginx use the following command `sudo apt-get install nginx -y`

Make sure nginx is running by using your web browser and browsing to `http://example-ip.com`

## Simple reverse proxy
We will start with a very simple example, in Nginx you can use the `proxy_pass` directive to define a
reverse proxy, this directive can be added to any Nginx block as required.

Let's say we have a site configuration called `example.conf` to define a reverse proxy in it we use:

{: .file-excerpt }
/etc/nginx/sites-enabled/example.conf
:   ~~~ nginx
    location /example1 {
      proxy_pass http://www.example1.com/;
    }
    location /example2 {
      proxy_pass http://www.example2.com/;
    }
    ~~~

The above configuration file defines two reverse proxies based on the url.

When you try to open `http://example.com/example1`, Nginx forwards the request to http://www.example1.com/
and when you try to open `http://example.com/example2`, Nginx forwards the request to http://www.example2.com/

The idea of using Nginx reverse proxy is simple, write the configuration you want then add proxy_pass directives
when needed, however Nginx can proxy non-HTTP protocols using appropriate *_proxy directives such as:
* fastcgi_pass passes a request to a FastCGI server
* uwsgi_pass passes a request to a uwsgi server
* scgi_pass passes a request to an SCGI server
* memcached_pass passes a request to a memcached server

In the following sections we will look at examples of using proxy_pass directive with different configurations.

### Use Different Host Names
An example of using reverse proxy is to use a different backend server for each host name used.

Let's say we have two configuration files one for example.com and the other for assets.example.com

The first one is for serving the site and the other is for serving it assets.

{: .file }
/etc/nginx/sites-enabled/example.com.conf
:   ~~~ nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server ipv6only=on;

    server_name example.com;

    location / {
            proxy_pass http://localhost:8080;
    }
}
    ~~~

    {: .file }
    /etc/nginx/sites-enabled/assets.example.com.conf
    :   ~~~ nginx
    server {
        listen 80 default_server;
        listen [::]:80 default_server ipv6only=on;

        server_name assets.example.com;

        location / {
                proxy_pass http://localhost:8080/assets;
        }
    }
        ~~~

So here a request to `example.com` will be served from the web server listening
on port 8080 and running on localhost and a request to `assets.example.com` will be served from
the same server but with adding `/assets` to the start of url.

### Use Different Ports
Sometimes we might have a server running on a port in the private network and we want to use Nginx to access it, we can achieve this using reverse proxies.

{: .file }
/etc/nginx/sites-enabled/elasticsearch.conf
:   ~~~ nginx
server {
    listen 80 default_server;

    server_name elasticsearch.example.com;

    location / {
            proxy_pass http://elastic_host:9200;
            auth_basic "Private Property";
            auth_basic_user_file /etc/nginx/.elastic.htpasswd;
    }
}
    ~~~

    {: .file }
    /etc/nginx/sites-enabled/kibana.conf
    :   ~~~ nginx
    server {
        listen 80 default_server;

        server_name kibana.example.com;

        location / {
                proxy_pass http://kibana_host:5681;
                auth_basic "Private Property";
                auth_basic_user_file /etc/nginx/.kibana.htpasswd;
        }
    }
        ~~~

In this case a request to `elasticsearch.example.com` will be served from `http://elastic_host:9200`
where an elasticsearch server is running on host called elastic_host, and if the request is for
`kibana.example.com` it will be served from `http://kibana_host:5681` where a kibana server is
running on a host called kibana_host.

{: .note}
>
> For more information about auth_basic and auth_basic_user_file directives check [this](http://nginx.org/en/docs/http/ngx_http_auth_basic_module.html).

### Passing Request Headers to Backend Servers
Sometimes your web application needs to know the real IP address of the user who is visiting your website,
in case of a reverse proxy the backend server only sees the proxy IP address.
This can be solved by passing the IP address of the client using HTTP request headers, the `proxy_set_header`
directive is used for this.

{: .file }
/etc/nginx/sites-enabled/example.com.conf
:   ~~~ nginx
server {
    listen 80 default_server;

    server_name example.com;

    location / {
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header Host $host;
            proxy_pass http://example.org:9200;
    }
}
    ~~~

### Choosing a Bind Address
If your backend server is configured to only accept connections from certain IP addresses
and your proxy server has multiple network interfaces then you want your reverse proxy to choose
the right source IP address when connecting to a backend server, this can be achieved with `proxy_bind`
directive as showed next

{: .file-excerpt }
/etc/nginx/sites-enabled/example.conf
:   ~~~ nginx
    location /example1 {
      proxy_bind 192.0.2.1;
      proxy_pass http://www.example1.com/;
    }
    ~~~

Now when your reverse proxy connects with the backend server it will use the source IP address
specified in the directive which is `192.0.2.1`.

### Buffering
When Nginx receives a response from the backend server it buffers the response before sending
it directly to the client which helps to optimize performance with slow clients, however buffering
can be controlled with these directives `proxy_buffering`, `proxy_buffers` and `proxy_buffer_size`.
The following shows an example

{: .file-excerpt }
/etc/nginx/sites-enabled/example.conf
:   ~~~ nginx
    location /example1 {
      proxy_buffers 8 2k;
      proxy_buffer_size 2k;
      proxy_pass http://www.example1.com/;
    }
    ~~~
`proxy_buffering` directive is used to enable or disable buffering, it can be disabled with
`proxy_buffering off;`, buffering is enabled by default.

`proxy_buffers` controls the number and size of buffers allocated to each request in the example
above there are 8 buffers with each one 2 kilobytes in size.

`proxy_buffer_size` controls the size of initial buffer where the response is first stored for all requests.

## Conclusion
In this tutorial we learned the basics of using Nginx as a reverse proxy to serve content from multiple
locations and from servers which are not exposed to the internet, we also learned about buffering responses
from backend servers to Nginx and about using a specific IP address when connecting to the backend server.

----
