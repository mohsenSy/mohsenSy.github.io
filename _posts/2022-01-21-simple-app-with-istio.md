---
layout: post
title:  "Run a simple nginx pod in Digital Ocean Kubernetes Cluster with istio 1.12"
date:   2022-01-21 00:02:00 +0300
categories: sre
summary: Here we will use istio 1.12 installed in DOKS to run a simple nginx pod.
---

# Introduction
In a previous tutorial found [here]({% post_url 2022-01-21-install-istio-1.12-with-terraform %}), we installed istio version 1.12
using terraform in a Digital Ocean Kubernetes Cluster, today we will continue the work of the previous tutorial
and use istio gateways and Virtual Services to expose a simple nginx pod using istio service mesh.

This tutorial assumes that you have istio 1.12 installed on Digital Ocean kubernetes cluster and your kubectl
is connected to the cluster, refer to the previous tutorial for help.

In this tutorial we will:
* Learn about istio Gateways and Virtual Services.
* Use nginx server to test Istio gateways and virtual services.
* Use istio-ingress logs to debug issues in our service mesh.

# Istio Gateway
Gateways are used to describe a Load Balancer operating at the edge of your service mesh, in order for the gateways
to work you need to define a proxy running at the edge of your mesh, we did this in the last tutorial using the
Gateway helm chart installed in the istio-system namespace.

This chart runs a pod with envoy proxy image and it can be configured with the gateway resources, here is a simple
defenition of the Gateway resource

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: my-gateway
spec:
  selector:
    istio: ingress
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - app.test.com
```

From the previous YAML file we can see in the specs two important keys, the first one is `selector` and it is used
to select the istio-ingress pod which runs the envoy proxy at the edge of the mesh and we also have the `servers` key
which defines the listening interfaces for external connections, here we have on HTTP server with port 80 and uses the
host `app.test.com`, this will match HTTP requests coming to the external Load Balancer on port 80 and host `app.test.com`.

Write this to a file called `gateway.yaml`, but before we apply it let us have a look at the listening interfaces in
the `istio-ingress` pod, use this command to check for listening interfaces:

```
> kubectl exec -n istio-system deploy/istio-ingress -- netstat -ltnp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:15021           0.0.0.0:*               LISTEN      15/envoy
tcp        0      0 0.0.0.0:15021           0.0.0.0:*               LISTEN      15/envoy
tcp        0      0 0.0.0.0:15090           0.0.0.0:*               LISTEN      15/envoy
tcp        0      0 0.0.0.0:15090           0.0.0.0:*               LISTEN      15/envoy
tcp        0      0 127.0.0.1:15000         0.0.0.0:*               LISTEN      15/envoy
tcp        0      0 127.0.0.1:15004         0.0.0.0:*               LISTEN      1/pilot-agent
tcp6       0      0 :::15020                :::*                    LISTEN      1/pilot-agent
```

As you can see the output does not contain any listening process for HTTP port 80.

Now try to send an HTTP request to the Load Balancer created by the `itsio-ingress` service, first get
the Load Balancer's IP with this command

```bash
INGRESS_HOST=$(kubectl -n istio-system get service istio-ingress -ojsonpath='{.status.loadBalancer.ingress[0].ip}')
```

Now execute curl command against the ingress IP address with this command

```bash
> curl -v $INGRESS_HOST
*   Trying 138.68.127.3:80...
* TCP_NODELAY set
* Connected to 138.68.127.3 (138.68.127.3) port 80 (#0)
> GET / HTTP/1.1
> Host: 138.68.127.3
> User-Agent: curl/7.68.0
> Accept: */*
>
* Recv failure: Connection reset by peer
* Closing connection 0
curl: (56) Recv failure: Connection reset by peer
```

As you can see you got connection reset error because no process is listening for this port in the
istio-ingress pod, now add the gateway with this command

```bash
kubectl apply -f gateway.yaml
```

Try to list the listnening ports again

```bash
> kubectl exec -n istio-system deploy/istio-ingress -- netstat -ltnp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:15021           0.0.0.0:*               LISTEN      15/envoy
tcp        0      0 0.0.0.0:15021           0.0.0.0:*               LISTEN      15/envoy
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      15/envoy
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      15/envoy
tcp        0      0 0.0.0.0:15090           0.0.0.0:*               LISTEN      15/envoy
tcp        0      0 0.0.0.0:15090           0.0.0.0:*               LISTEN      15/envoy
tcp        0      0 127.0.0.1:15000         0.0.0.0:*               LISTEN      15/envoy
tcp        0      0 127.0.0.1:15004         0.0.0.0:*               LISTEN      1/pilot-agent
tcp6       0      0 :::15020                :::*                    LISTEN      1/pilot-agent
```

You can see from the output that we have a new process listening on port 80, try to
use curl now and see what you will get:

```bash
> curl -v $INGRESS_HOST
*   Trying 188.166.195.70:80...
* TCP_NODELAY set
* Connected to 188.166.195.70 (188.166.195.70) port 80 (#0)
> GET / HTTP/1.1
> Host: 188.166.195.70
> User-Agent: curl/7.68.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 404 Not Found
< date: Sun, 16 Jan 2022 13:26:29 GMT
< server: istio-envoy
< content-length: 0
<
* Connection #0 to host 188.166.195.70 left intact
```

This time you got a 404 error because we only defined the entry point but no routing is defined inside
the service mesh, this is where Virtual Services come to play.

For more information about **Istio Gateways** check [here](https://istio.io/latest/docs/reference/config/networking/gateway/)

# Istio Virtual Services
Virtual Services are used to route requests as they enter the mesh (if the Virtual Service is linked with a gateway)
or are used to route requests after they enter the service mesh (if the Virtual Service is not linked with a gateway),
so far we defined a Gateway to accept requests from the outside and enter them in the service mesh, now let us use
a Virtual Service to define the route for the request after it enters the mesh.

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: my-route
spec:
  hosts:
  - app.test.com
  gateways:
  - my-gateway
  http:
  - name: "my-app"
    route:
    - destination:
        host: my-app
```

This Virtual Service defines a route for requests arriving at the `my-gateway` with host `app.test.com` and they are
routed to a kubernetes service called `my-app` in the `default` namespace.

Write this to a file called `virtual-service.yaml` and apply the file using this command

```bash
kubectl apply -f virtual-service.yaml
```

Now if we try to access the Load Balancer's IP with this command

```
> curl -v $INGRESS_HOST
*   Trying 188.166.195.70:80...
* TCP_NODELAY set
* Connected to 188.166.195.70 (188.166.195.70) port 80 (#0)
> GET / HTTP/1.1
> Host: 188.166.195.70
> User-Agent: curl/7.68.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 404 Not Found
< date: Sun, 16 Jan 2022 13:39:26 GMT
< server: istio-envoy
< content-length: 0
<
* Connection #0 to host 188.166.195.70 left intact
```

We get the same error because no service called `my-app` is defined in the cluster, so we need now
to create a test service and deploy it to the cluster.

For more information about **Istio Virtual Services** check [here](https://istio.io/latest/docs/reference/config/networking/virtual-service/)

# Use nginx as a test service

To test the virtual service we will deploy an nginx pod with a service called `my-app` to access
the nginx server using the istio-ingress service.

Write this YAML to a file called `nginx.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  labels:
    name: my-app
spec:
  containers:
  - name: my-app
    image: nginx
    resources:
      limits:
        memory: "128Mi"
        cpu: "500m"
    ports:
      - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 80
```

Apply it with this command

```
kubectl apply -f nginx.yaml
```

Now we have a pod called `my-app` which runs nginx image, a service called `my-app` which points to the
nginx pod, and a virtual service called `my-route` which links the host `app.test.com` with the service.

Test again using curl with this command, you will get this

```
> curl -v $INGRESS_HOST
*   Trying 10.98.125.155:80...
* TCP_NODELAY set
* Connected to 10.98.125.155 (10.98.125.155) port 80 (#0)
> GET / HTTP/1.1
> Host: 10.98.125.155
> User-Agent: curl/7.68.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 404 Not Found
< date: Thu, 20 Jan 2022 21:19:53 GMT
< server: istio-envoy
< content-length: 0
<
* Connection #0 to host 10.98.125.155 left intact
```

As you can see, you got the same error as before, as if we did not add any virtual service or pods. In the next
section we will debug our setup to find the hidden errors that we have here.

# Debugging istio configs
Many times you will get error messages when trying to access your services in istio mesh and knowing how to debug these
errors is very important for your work, we will take a look at the access logs in istio ingress gateway to check for errors.

Print the logs of istio-ingress deployment with this command

```
INGRESS_POD=$(kubectl get pods -n istio-system -l app=istio-ingress -ojsonpath="{.items[0].metadata.name}" | xargs)
kubectl logs $INGRESS_POD -n istio-system
```

```
[2022-01-20T22:36:12.754Z] "GET / HTTP/1.1" 404 NR route_not_found - "-" 0 0 0 - "192.168.0.6" "curl/7.68.0" "4fc41716-078a-4db5-9d7c-6cd80251c8a9" "138.68.127.3" "-" - - 10.244.0.233:80 192.168.0.6:20020 - -
[2022-01-20T22:37:03.366Z] "GET / HTTP/1.1" 404 NR route_not_found - "-" 0 0 0 - "192.168.0.5" "curl/7.68.0" "839a54e7-b789-46c1-b45f-4cde36e0359c" "138.68.127.3" "-" - - 10.244.0.233:80 192.168.0.5:48618 - -
[2022-01-20T22:37:28.000Z] "GET / HTTP/1.1" 404 NR route_not_found - "-" 0 0 0 - "192.168.0.6" "curl/7.68.0" "fca45636-d57d-44c9-8f74-c7471e59e981" "138.68.127.3" "-" - - 10.244.0.233:80 192.168.0.6:20178 - -
```

This is part of the output, as we can see we have a `route_not_found` error, to diagonise this we will start with the gateway, if you go back
and take a look at the gateway you will notice we have a `hosts` field with value of `- app.test.com`, this means that this gateway
will pass requests sent to this host only, so we must add the host to curl command like this

```
> curl -v -H "Host: app.test.com" $INGRESS_HOST
*   Trying 138.68.127.3:80...
* TCP_NODELAY set
* Connected to 138.68.127.3 (138.68.127.3) port 80 (#0)
> GET / HTTP/1.1
> Host: app.test.com
> User-Agent: curl/7.68.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 503 Service Unavailable
< content-length: 19
< content-type: text/plain
< date: Thu, 20 Jan 2022 22:38:26 GMT
< server: istio-envoy
<
* Connection #0 to host 138.68.127.3 left intact
no healthy upstream
```

No we got another error, let us look again at the logs:

```
kubectl logs $INGRESS_POD -n istio-system
```
```
[2022-01-20T22:38:26.354Z] "GET / HTTP/1.1" 503 UH no_healthy_upstream - "-" 0 19 0 - "192.168.0.3" "curl/7.68.0" "069c37c4-bead-49ae-8ef3-fe9fdca1602b" "app.test.com" "-" outbound|80||my-app.default.svc.cluster.local - 10.244.0.233:80 192.168.0.3:43900 - my-app
```

The error is now `no_healthy_upstream` which means there is something wrong with our service, to debug the service we will try to print
its endpoints with this command

```
> kubectl get endpoints my-app
NAME     ENDPOINTS   AGE
my-app   <none>      26m
```

From the output above we see that the service does not have any endpoints at all, which means any requests sent to this service
it will response with 503 error because there are no pods for it to send requests to them, if we go back at the service's yaml
file, we see that the selector for the service is `app: my-app`, let us find pods with this selector using this command

```
> kubectl get pods -n app=my-app
No resources found in app=my-app namespace.
```

There are no pods with this label, if we look at the Pod's yaml file for the nginx pod it has these labels `name: my-app`, but
our service has a selector of `app: my-app`, so we must change the label in nginx's pod to `app: my-app` and apply again with this command

```
kubectl apply -f nginx.yaml
```

Now let us try again to curl nginx

```
> curl -v -H "Host: app.test.com" $INGRESS_HOST
*   Trying 138.68.127.3:80...
* TCP_NODELAY set
* Connected to 138.68.127.3 (138.68.127.3) port 80 (#0)
> GET / HTTP/1.1
> Host: app.test.com
> User-Agent: curl/7.68.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< server: istio-envoy
< date: Thu, 20 Jan 2022 22:40:05 GMT
< content-type: text/html
< content-length: 615
< last-modified: Tue, 28 Dec 2021 15:28:38 GMT
< etag: "61cb2d26-267"
< accept-ranges: bytes
< x-envoy-upstream-service-time: 4
<
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
* Connection #0 to host 138.68.127.3 left intact
```

It looks like it worked now, congratulations you managed to debug the issues in istio using its access logs, always
use logs when debugging issues they contain a lot of helpful information.

**HINT**: To get the full features of istio in your services you must enable side-car injection in your namespaces by
adding this label `istio-injection=enabled` to your namespace using this command

```
kubectl label namespace default istio-injection=enabled
```

# Conclusion

In this tutorial we learned how to use Istio Gateways and Virtual Services to route traffic
from outside to our services in the cluster, we also used istio's access logs to debug
issues with our setup and learned how to use `get endpoints` command to debug issues
with k8s services.

I hope you find the content useful for any comments or questions you can contact me
on my email address
[mouhsen.ibrahim@gmail.com](mailto:mouhsen.ibrahim@gmail.com?subject=simple-app-with-istio)

Stay tuned for more tutorials. :) :)
