---
layout: post
title:  "Install istio 1.12 with terraform"
date:   2022-01-21 00:01:00 +0300
categories: sre
summary: Here we will install latest istio with terraform on Digital Ocean kubernetes cluster
---

# Introduction
In a previous tutorial found [here]({% post_url 2021-04-10-install-istio-with-terraform %}), we installed istio version 1.9.2
using terraform version 0.14, but a lot has changed ever since so today we will install istio version 1.12 with a new terraform
version at least 1.0.0, this should be very similar but with one major change in istio helm installation, we no longer need
to download the istio helm charts locally to install them, they are now published here https://istio-release.storage.googleapis.com/charts

In this tutorial we will:
* Install terraform.
* Create a Digital Ocean Kubernetes Cluster using terraform.
* Install helm.
* Use terraform to install istio 1.12 in Kubernetes Cluster.

**HINT**: This is an improved version of the previous tutorial, as so much have changed ever since.

# Terraform
Modern infrastructure is managed using Infrastructure as Code Tools, [terraform](https://terraform.io) is one of
the most famous tools in this domain, it can be used to describe any kind of infrastructure using scripts and
then it will modify your existing infrastructure to match the state defined in terraform.

You can install terraform from this [page](https://www.terraform.io/downloads.html) accorsing to your OS.

If you are running Linux use these commands

```bash
wget https://releases.hashicorp.com/terraform/1.1.3/terraform_1.1.3_linux_amd64.zip
unzip terraform_1.1.3_linux_amd64.zip
sudo install -m 755 terraform /usr/local/bin
rm terraform_1.1.3_linux_amd64.zip terraform
```

To make sure terraform is installed use this command

```bash
terraform version
```

It will print the version of terraform

```
Terraform v1.1.3
```


# Digital Ocean Kubernetes Cluster
[Digital Ocean](https://digitalocean.com/) offers a managed Kubernetes service called [DOKS](https://docs.digitalocean.com/products/kubernetes/), with
this service you can create a Kubernetes cluster very easily without going into the effort of creating your own, here we will use terraform
to create the cluster.

We will now create multiple terraform scripts, the first one is called `provider.tf`:

```terraform
terraform {
  required_providers {
    digitalocean = {
        source = "digitalocean/digitalocean"
        version = "2.17.0"
    }
  }
}
provider "digitalocean" {
}
```

In the first block we define the required providers for our setup, we only need Digital Ocean provider here,
second we specify the configuration for the provider, the configuration is left empty to use doctl command
line configuration.

To authenticate using doctl use this command

```
doctl auth init
```

The second script will be in a file called `doks.tf`, this will create the kubernetes cluster for us:

```terraform
resource "digitalocean_kubernetes_cluster" "my_cluster" {
  name = "my-cluster"
  region = "fra1"
  version = "1.21.5-do.0"

  node_pool {
      name = "my-pool"
      size = "s-2vcpu-4gb"
      node_count = 3
  }
}
```

Here we are using `digitalocean_kubernetes_cluster` resource to create a DOKS called `my-cluster` with version `1.21.5-do.0`
in the frankfurt data center, witha  node pool of size 3 called `my-pool`, it has nodes of size `s-2vcpu-4gb` which are
standard size nodes with 2 vCPUs and 4 GB of RAM.

You can use these commands to get a list of available cluster versions and node sizes

```
doctl kubernetes options versions
doctl kubernetes options sizes
```

After we have defined the configuration we can apply it, but first we must initalize terraform with this command

```
terraform init
```
This will download the terraform provider to a directory called `.terraform`, now we are ready to apply the resources
we defined using this command

```
terraform apply
```

Terraform will prmpt you to type `yes` to continue, go ahead :)

Wait until the cluster is ready.

Once the cluster is ready you can find it in Digital Ocean control panel [here](https://cloud.digitalocean.com/kubernetes/clusters)

![]({{ site.url }}/assets/images/doks-new.jpg)

Now after the cluster is ready we will install helm and use terraform to install istio helm chart in the cluster.

# Helm

[Helm](https://helm.sh/) is simply the package manager for Kubernetes, it can be used to install applications in
kubernetes clusters, we can use it to install complex apps rather than managing these apps directly using
kubernetes manifests, we use helm to generate all the required manifests for us and apply them, helm can also
be used to manage and upgrade these apps on demand.

Follow instructions [here](https://helm.sh/docs/intro/install/) to install it based on your OS.

if you are using Linux use these commands

```
wget https://get.helm.sh/helm-v3.7.2-linux-amd64.tar.gz
tar zxf helm-v3.7.2-linux-amd64.tar.gz
sudo install -m 755 linux-amd64/helm /usr/local/bin
rm -rf linux-amd64 helm-v3.7.2-linux-amd64.tar.gz
```

Now we need to configure the helm and kubernetes providers, which are used to install helm charts in the cluster,
add these lines to `provider.tf`

```terraform
provider "helm" {
  kubernetes {
    host = digitalocean_kubernetes_cluster.my_cluster.endpoint
    token = digitalocean_kubernetes_cluster.my_cluster.kube_config[0].token
    cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.my_cluster.kube_config[0].cluster_ca_certificate)
  }
}
provider "kubernetes" {
    host = digitalocean_kubernetes_cluster.my_cluster.endpoint
    token = digitalocean_kubernetes_cluster.my_cluster.kube_config[0].token
    cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.my_cluster.kube_config[0].cluster_ca_certificate)
}
```

Here we are telling terraform to use helm provider and connect to our kubernetes cluster.

Before we start installing istio with helm in terraform, we need to create the `istio-system` namespace,
add these lines to `doks.tf`, which create the new kubernetes namespace.

```
resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
}

```

Create a new terraform file called `k8s-istio.tf` to be used for installing istio

```
resource "helm_release" "istio_base" {
  name  = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart = "base"

  timeout = 120
  cleanup_on_fail = true
  force_update    = false
  namespace       = kubernetes_namespace.istio_system.metadata.0.name


  depends_on = [ digitalocean_kubernetes_cluster.my_cluster]
}

resource "helm_release" "istiod" {
  name  = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart = "istiod"

  timeout = 120
  cleanup_on_fail = true
  force_update    = false
  namespace       = kubernetes_namespace.istio_system.metadata.0.name

  set {
    name = "meshConfig.accessLogFile"
    value = "/dev/stdout"
  }


  depends_on = [ digitalocean_kubernetes_cluster.my_cluster, helm_release.istio_base]
}

resource "helm_release" "istio_ingress" {
  name  = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart = "gateway"

  timeout = 500
  cleanup_on_fail = true
  force_update    = false
  namespace       = kubernetes_namespace.istio_system.metadata.0.name

  depends_on = [ digitalocean_kubernetes_cluster.my_cluster, helm_release.istiod]
}
```

Here we are creating 3 helm releases for Istio:

* The first one is called `istio_base`, this one install the CRDs needed by istio to run.
* The second one is called `istiod`, this one installs istio daemon, which includes many
    services including pilot, citadel and others ...
* The third one is `istio-ingress` which create `istio-ingress`
    service that control traffic comming inside the mesh.

Note the `depends_on` attributes, these define explicit dependenies between the helm charts, istiod depends on
istio_base to work, so it can create its own objects based on CRDs created in istio-base and istio-ingress depend on istiod to work.

Now we are ready to apply terraform again but first we must re-call `init` because we added new providers

```
terraform init
terraform apply
```

Wait for it to finish.

To check if the helm chart was installed you can connect to the cluster first using this command

```
doctl kubernetes cluster kubeconfig save <Cluster UUID>
```

You can find the UUID in yot cluster page, as shown bellow

![]({{ site.url }}/assets/images/doks-connect.jpg)

Use these two commands to check the status of the helm release

```
helm ls -n istio-system
```

You will get an output similar to this

```
> helm ls -n istio-system
NAME         	NAMESPACE   	REVISION	UPDATED                                	STATUS  	CHART         	APP VERSION
istio-base   	istio-system	1       	2022-01-20 22:12:29.876005556 +0100 CET	deployed	base-1.12.2   	1.12.2
istio-ingress	istio-system	1       	2022-01-20 22:12:51.591794182 +0100 CET	deployed	gateway-1.12.2	1.12.2
istiod       	istio-system	1       	2022-01-20 22:12:38.123926824 +0100 CET	deployed	istiod-1.12.2 	1.12.2
```

Where you can find all the four helm charts you just installed.

Use this command to check the services in `istio-system` namespace:

```
kubectl get service -n istio-system
```

In the output you can find a service of type Load Balancer called `istio-ingress` which has an external IP

```
> kubectl get service -n istio-system
NAME            TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)                                      AGE
istio-ingress   LoadBalancer   10.245.100.78   138.68.127.3   15021:31020/TCP,80:32742/TCP,443:32000/TCP   21m
istiod          ClusterIP      10.245.183.37   <none>         15010/TCP,15012/TCP,443/TCP,15014/TCP        22m
```

You can use this IP address to connect to the service mesh. However, if you try that now you will get a connection reset
error because we did not define a gateway for the service mesh and don't have any routing resources, we will add the
gateway and routing resources to route traffic to an nginx pod in the next tutorial.

# Conclusion

In this long tutorial we learned how to install Istio version 1.12 in a Digital Ocean Kubernets cluster using helm
and terraform, in the next tutorial we will use istio Gateways and Virtual Services to route traffic to a nginx pod.

I hope you find the content useful for any comments or questions you can contact me
on my email address
[mouhsen.ibrahim@gmail.com](mailto:mouhsen.ibrahim@gmail.com?subject=using-terraform-to-install-isio-1.12-to-doks)

Stay tuned for more tutorials. :) :)
