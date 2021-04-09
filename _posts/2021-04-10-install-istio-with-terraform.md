---
layout: post
title:  "Install Istio with terraform in Digital Ocean Kubernetes Cluster"
date:   2021-04-10 01:12:00 +0300
categories: sysadmin
summary: Here I will show you how to use use terraform to install Istio 1.9.2 in Digital Ocean Kubernetes Cluster
---

# Introduction
Modern applications usually use the microservices architecture to create multiple loosely coupled services that
communicate with each other using well defined APIs, this archiecture is best implemented using Docker containers
created and managed in Kubernetes Clusters, using Kubernetes gives us the ability to deploy these services using
multiple Kubernetes deployments and communicate with each other.

Istio comes to play as a service mesh which manages and secures all the communications between services, it can also
be used for monitoring, routing requests to services based on URLs, headers, etc... Istio is an important addition
to Kubernetes cluster to help you in connecting all your services together and securing the communication between them.

# What will we do?

In this tutorial we will:

* Install terraform.
* Create a Digital Ocean Kubernetes Cluster using terraform.
* Install helm and download the istio helm charts.
* Use terraform to install istio helm charts in Kubernetes Cluster.

# Terraform
Modern infrastructure is managed using Infrastructure as Code Tools, [terraform](https://terraform.io) is one of
the most famous tools in this domain, it can be used to describe any kind of infrastructure using scripts and
then it will modify your existing infrastructure to match the state defined in terraform.

You can install terraform from this [page](https://www.terraform.io/downloads.html) accorsing to your OS.

If you are running Linux use these commands

```bash
wget https://releases.hashicorp.com/terraform/0.14.8/terraform_0.14.8_linux_amd64.zip
unzip terraform_0.14.8_linux_amd64.zip
sudo install -m 755 terraform /usr/local/bin
rm terraform_0.14.8_linux_amd64.zip terraform
```

To make sure terraform is installed use this command

```bash
terraform version
```

It will print the version of terraform

```
Terraform v0.14.8
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
        version = "2.7.0"
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
  version = "1.18.14-do.0"

  node_pool {
      name = "my-pool"
      size = "s-2vcpu-4gb"
      node_count = 4
  }
}
```

Here we are using `digitalocean_kubernetes_cluster` resource to create a DOKS called `my-cluster` with version `1.18.14-do.0`
in the frankfurt data center, witha  node pool of size 4 called `my-pool`, it has nodes of size `s-2vcpu-4gb` which are
standard size nodes with 2 vCPUs and 4 GB of RAM.

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

![]({{ site.url }}/assets/images/doks-new.png)

Now after the cluster is ready we will install helm and use terraform to install istio helm chart in the cluster.

# Helm

[Helm](https://helm.sh/) is simply the package manager for Kubernetes, it can be used to install applications in
kubernetes clusters, we can use it to install complex apps rather than managing these apps directly using
kubernetes manifests, we use helm to generate all the required manifests for us and apply them, helm can also
be used to manage and upgrade these apps on demand.

Follow instructions [here](https://helm.sh/docs/intro/install/) to install it based on your OS.

if you are using Linux use these commands

```
wget https://get.helm.sh/helm-v3.5.3-linux-amd64.tar.gz
tar zxf helm-v3.5.3-linux-amd64.tar.gz
sudo install -m 755 linux-amd64/helm /usr/local/bin
rm -rf linux-amd64 helm-v3.5.3-linux-amd64.tar.gz
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

Before we start installing istio with helm in terraform, we need to create the `istio-system` namespace, add
these lines to `doks.tf`, which create the new kubernetes namespace.

```
resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
}
```

Now we need to download istio release using this command

```
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.9.2 sh -
```

This installs `istio version 1.9.2` to a directory called `istio-1.9.2` it contains the helm
charts used to install istio.

Create a new script called `k8s-istio.tf` to be used for installing istio

```
resource "helm_release" "istio_base" {
  name  = "istio-base"
  chart = "istio-1.9.2/manifests/charts/base"

  timeout = 120
  cleanup_on_fail = true
  force_update    = true
  namespace       = "istio-system"


  depends_on = [digitalocean_kubernetes_cluster.my_cluster, kubernetes_namespace.istio_system]
}

resource "helm_release" "istiod" {
  name  = "istiod"
  chart = "istio-1.9.2/manifests/charts/istio-control/istio-discovery"

  timeout = 120
  cleanup_on_fail = true
  force_update    = true
  namespace       = "istio-system"

  depends_on = [digitalocean_kubernetes_cluster.my_cluster, kubernetes_namespace.istio_system, helm_release.istio_base]
}

resource "helm_release" "istio_ingress" {
  name  = "istio-ingress"
  chart = "istio-1.9.2/manifests/charts/gateways/istio-ingress"

  timeout = 120
  cleanup_on_fail = true
  force_update    = true
  namespace       = "istio-system"

  depends_on = [digitalocean_kubernetes_cluster.my_cluster, kubernetes_namespace.istio_system, helm_release.istiod]
}

resource "helm_release" "istio_egress" {
  name  = "istio-egress"
  chart = "istio-1.9.2/manifests/charts/gateways/istio-egress"

  timeout = 120
  cleanup_on_fail = true
  force_update    = true
  namespace       = "istio-system"

  depends_on = [digitalocean_kubernetes_cluster.my_cluster, kubernetes_namespace.istio_system, helm_release.istiod]
}

```

Here we are creating 4 helm releases for Istio:

* The first one is called `istio_base`, this one install the CRDs needed by istio to run.
* The second one is called `istiod`, this one installs istio daemon, which includes many
    services including pilot, citadel and others ...
* The third and fourth ones are `istio-ingress` and `istio-eggress` which create `istio-ingressgateway`
    and `istio-egressgateway` services that control traffic comming inside the mesh or leaving it.

Note the `depends_on` attributes, these define explicit dependenies between the helm charts, istiod depends on
istio_base to work, so it can create its own objects based on CRDs created in istio-base and istio-ingress
and istio-egress depend on istiod to work.

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

![]({{ site.url }}/assets/images/doks-connect.png)

Use this command to check the status of the helm release

```
helm ls -n istio-system
```

You will get an output similar to this

```
NAME         	NAMESPACE   	REVISION	UPDATED                                 	STATUS  	CHART                	APP VERSION
istio-base   	istio-system	1       	2021-04-10 00:56:02.308467724 +0200 CEST	deployed	base-1.9.2
istio-egress 	istio-system	1       	2021-04-10 00:56:21.904767659 +0200 CEST	deployed	istio-egress-1.9.2
istio-ingress	istio-system	1       	2021-04-10 00:56:21.904966242 +0200 CEST	deployed  istio-ingress-1.9.2
istiod       	istio-system	1       	2021-04-10 00:56:05.393867071 +0200 CEST	deployed	istio-discovery-1.9.2
```

Where you can find all the four helm charts you just installed.

# Conclusion

In this long tutorial we learned how to install Istio in a Digital Ocean Kubernets cluster using helm
and terraform, in the next tutorial we will explore what Istio is and how it can be used to create a simple
microservice.

I hope you find the content useful for any comments or questions you can contact me
on my email address
[mouhsen.ibrahim@gmail.com](mailto:mouhsen.ibrahim@gmail.com?subject=using-terraform-to-install-isio-to-doks)

Stay tuned for more tutorials. :) :)
