---
layout: post
title:  "Nginx as a reverse proxy"
date:   2018-02-08 16:16:00 +0300
categories: sysadmin
summary: Here I will describe the use of nginx server as a reverse proxy for your backend applications
---

## What is a Reverse Proxy?

A reverse proxy is a type of proxy server which forwards client requests to backend servers.

NGINX offers excellent security, acceleration, and load balancing features, making it one of the most popular choices to serve as a reverse proxy. When used as a reverse proxy NGINX handles all client interaction, so it can provide security and optimization to backend services that often lack these features.

For more information on the benefits of using NGINX as a reverse proxy, see the official [documentation](https://www.nginx.com/resources/glossary/reverse-proxy-server/).

### Install NGINX

Debian and Ubuntu:

    sudo apt install nginx

CentOS and RHEL:

    sudo yum install epel-release && sudo yum install nginx

## Create a Python Test Server

The sample app will use the `http.server` module (available for Python 3.4 and above) to create a simple HTTP server that will serve static content on `localhost`.


### Create a Sample App

1.  Since the module will serve files in the working directory, create a new one for this example:

        mkdir myapp
        cd myapp

2.  Create a test page for the app to serve:

        echo "hello world" > index.html

3.  Start a basic http server:

        python3 -m http.server 8000 --bind 127.0.0.1


Python 2.7 has an equivalent module via `python -m SimpleHTTPServer 8000` that listens to all interfaces but does not have an option to bind to a specific address from the command line.

Using the `http.server` module from Python 3.4 and above is highly recommended as it allows a convenient way to bind to a specific IP.

4.  Open a new terminal. Use `curl` to check the HTTP headers:

        curl -I localhost:8000

    Review the output to confirm that the server is `SimpleHTTP`:

```
HTTP/1.0 200 OK
Server: SimpleHTTP/0.6 Python/3.5.3
Date: Tue, 19 Dec 2017 19:56:08 GMT
Content-type: text/html
Content-Length: 12
Last-Modified: Tue, 19 Dec 2017 14:45:31 GMT
```

5.  Test that the app is listening on `localhost`:

        curl localhost:8000

    This should print `hello world` to the console.

## Specify a Local Host

While this step is optional, specifying a local hostname will make it more convenient to point to the example app in later steps.

Add a hostname `myapp` to `/etc/hosts` that will only work locally:

```
127.0.0.1       localhost
127.0.0.1       myapp
127.0.1.1       localhost.localdomain   localhost

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

## Reverse Proxy Configuration

1.  Create an NGINX configuration file in `/etc/nginx/sites-available/myapp`:

```
server {
        listen 80;
        server_name myapp;

        location / {
                proxy_pass http://localhost:8000/;
        }
}
```

Remember to add a trailing slash `/` to the end of the URL in the `proxy_pass` directive so that NGINX can correctly generate a URL to be sent to the backend server.

2.  Enable the configuration by creating a symlink to `sites-enabled`:

        sudo ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/myapp

3.  Remove the default symlink:

        sudo rm /etc/nginx/sites-enabled/default

4.  Restart `nginx` to allow the changes to take effect:

        sudo systemctl restart nginx.service

5.  Test the proxy with curl:

        curl -I myapp

```
HTTP/1.1 200 OK
Server: nginx/1.10.3
Date: Tue, 19 Dec 2017 20:30:54 GMT
Content-Type: text/html
Content-Length: 12
Connection: keep-alive
Last-Modified: Tue, 19 Dec 2017 14:45:31 GMT
```

The server is now `nginx`. You can navigate to your public IP address in a browser and confirm that the application is publicly accessible on port 80.

### Non-HTTP Protocols
NGINX can proxy non-HTTP protocols using appropriate `*_proxy` directives such as:

* `fastcgi_pass` passes a request to a FastCGI server
* `uwsgi_pass` passes a request to a uwsgi server
* `scgi_pass` passes a request to an SCGI server
* `memcached_pass` passes a request to a memcached server

### Pass Request Headers to Backend Servers

Sometimes your backend application needs to know the IP address of the user who is visiting your website. With a reverse proxy, the backend server only sees the proxy IP address. This can be solved by passing the IP address of the client using HTTP request headers. The `proxy_set_header` directive is used for this.

```
server {
    listen 80;

    server_name myapp;

    location / {
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header Host $host;
            proxy_pass http://localhost:8000/;
    }
}
```

`$remote_addr` is a built-in variable that holds the IP address of the client; `$host` contains the hostname for the request. You can read more about these variables [here](https://nginx.org/en/docs/varindex.html).

### Choose a Bind Address
If your backend server is configured to only accept connections from certain IP addresses and your proxy server has multiple network interfaces, then you want your reverse proxy to choose the right source IP address when connecting to a backend server. This can be achieved with `proxy_bind`:

```
location / {
    proxy_bind 192.0.2.1;
    proxy_pass http://localhost:8000/;
}
```

Now when your reverse proxy connects with the backend server it will use `192.0.2.1` as the source IP address.

### Buffers
When NGINX receives a response from the backend server, it buffers the response before sending
it to the client, which helps optimize performance with slow clients. Buffering
can be turned off or customized with these directives: `proxy_buffering`, `proxy_buffers` and `proxy_buffer_size`.

```
location / {
    proxy_buffers 8 2k;
    proxy_buffer_size 2k;
    proxy_pass http://localhost:8000/;
}
```

 - `proxy_buffering` is used to enable or disable buffering.
 - `proxy_buffering off;` disables buffering. Buffering is enabled by default.
 - `proxy_buffers` controls the number and size of buffers allocated to each request. In the example above, there are 8 buffers, each of which is 2KB.
 - `proxy_buffer_size` controls the size of initial buffer where the response is first stored for all requests.
