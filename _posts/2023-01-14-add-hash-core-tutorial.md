---
layout: post
title:  "Managing a Mono repository using hash core"
date:   2023-01-14 00:07:00 +0200
categories: sre
summary: Here I will present my own tool for managing mono repositories called Hash Core.
---

# Note

Hash Core is now called Hash Kern, the name was changed due to another project called hash core found on the web, next
articles will use the new name.

# Introduction

[Hash Core](https://gitlab.com/hash-platform/hashkern) was developed to be used in managing different kinds of resources
in a mono repository, you can use YAML files to describe your resources and also your environments then use the CLI
to build, test, publish, and deploy your resources, it uses the hash of your resource's code and stores it in a state
storage to be able later to determine which resources have changed and which not, it has many features such as global outputs,
hash templates, dependency graph, and resource artifacts.

In this article we will learn about hash core features and how can we use them to manage our mono repositories.

*Alert*: Hash Core is still under active development, some important missing features are on our roadmap.

## What is hash core and its use cases?

As described above, has core is used in your mono repositories, it allows you to describe your different services, terraform configs,
Kubernetes manifests, docker images, configurations, etc... in YAML files and then you can use the CLI to run actions on them, these
actions are build, test, publish, and deploy, you can also define environments for your resources using YAML files and then specify
in which environment do you want to run an action, so you can deploy your service to staging or development using the CLI and selecting
the right environment which selects the right cluster for you.

### Use cases

* Manage different microservices in your repository and define dependencies between them and with terraform configs
    that create the required infrastructure to run them, this means that you will guarantee that the infrastructure
    is created first, and whenever it changes then it is deployed first and then the microservices are deployed.
* Manage multiple stages of terraform configs in your mono repository, you can define a terraform config to
    bootstrap your project, another one to create networks, and another one to create Kubernetes clusters
    and one more to deploy your helm charts using terraform, all of these dependencies can be easily defined
    in hash core and it will guarantee that they are applied in the right order.
* Manage multiple docker images that use each other in multi-stage builds, all of this using dependencies, also
    you can define an image to be used as a base for your microservices and Hash Core will automatically update
    your microservices once this image is updated,
* Deploy to multiple environments, environments are treated as resources in Hash Core which can be used as targets
    for running actions, you can define a development environment which connect to a development Kubernetes cluster
    and publishes images to a specific docker registry and the same thing for other environments.

Hash core is built to be generic when managing resources, so you can use it in many different ways and create your own
resources, in the next section we will learn about its main components.

## Hash Core Components

Here we list the main components of Hash Core and describe them.

### Resources

Resources are at the core of Hash Core, everything is a resource in Hash Core, they are defined using plugins that allow
us to easily add more resources to hash core. Even built-in resources are implemented using plugins.

A resource is defined using a class that inherits from BaseResource class in the resources package and it has a method
called `action` which must implement the supported actions for this resource, it must contain the logic for building,
testing, publishing, and deploying the resource.

For example, a terraform resource must run `terraform plan` on build, it might run `terraform fmt --check` on test, maybe nothing
on publish and run `terraform apply` on deploy.

The return value from the `action` method is stored in the state as it is, it can be used later in other actions, for example
we can store a value in the state when building a resource and then restore this value when testing the resource, this value
might be different between versions of the resource, however, Hash Core ensures that the value generated on build for version
x is used on test for the same version, the version is considered to be changed when the hash changes.

The return value must be a dictionary, two keys from this dictionary have special meanings, these are:

* **globals** The value of globals must be a dictionary, it is saved in state and can be queried later in specs
    for other resources and also in hash templates, these can be treated as outputs from a resource, for example
    all defined terraform outputs in a terraform resource are exported as globals which can be used in any
    other resources, not only in terraform resources, this enables us to link any other resource with
    any terraform resource and ensure that the other resource will get the new value if terraform
    output ever changes.

* **artifacts** Artifacts are also outputs from resources, but they can be files and they will be stored
    in the state storage, artifacts can be used in hash templates to link resources together, or can
    be simply stored in the state backend. Artifacts can also be simple text or a URL for example when
    publishing a docker image the URL of the published image in the registry is exported as an artifact.
    Hash core ensures that file artifacts are written to disk before running an action, which means if you
    run build on resource x and generate an artifact then if someone else or the CI runs test on this resource
    the artifact's file will be available with the same name and path as when it was generated by the build, so you
    don't have to worry about checking if the artifact's file exists and also you don't need to generate
    it twice on different machines.

### State storage

When running an action on a resource, its output along with the resource's hash is stored in state, the state
storage backends are implemented using plugins that allow us to store state in different storage backends
such as local disks, GCP buckets, digital ocean spaces, etc...

Currently, we have plugins for local disk, GCP buckets, and digital ocean spaces. However, we still need to test
the cloud storage solutions for performance.

A new state storage backend must implement some methods so it can be used in Hash Core, it must also
register itself as a plugin.

### Hash Templates

Hash Templates is a feature that allows you to dynamically include code in your resources based on artifacts
or outputs generated by other resources, it allows you to add new features to already existing tools that
will probably never be implemented, for example you can read terraform outputs directly into your Kubernetes
manifests in Kustomize, you can read image URLs from other docker image resources in your Dockerfiles or
your kustomize manifests, these features will probably never be added to Kustomize.

Here is a good use case:

Let's say you use external secrets operator to sync secrets from GCP to your clusters, and you
create some secrets using terraform configurations, you want to make sure that the external secret
resource is only created when you create the secret in terraform and you want to use the right name
for the secret, you can define the secret's name as an output of terraform resource then add a hash
template to your Kustomize resource and use that output in Kustomize this adds a dependency from
Kustomize to your resource.

A template is created by adding the `.hash` extension to the end of the file's name, those templates
are valid Jinja2 templates, inside them, you can access artifacts and globals using the `artifacts` function
and `globals` object, which are rendered by Hash Core always before executing the action, and removed
after the action was executed, they are also always included when calculating the hash even if
you use a different `match` list for hash calculation.

More features and functions will become available for hash templates to use in the future, which
make them a powerful tool in Hash Core, they have the disadvantage that you cannot use
your normal tools easily with hash templates as the rendered files don't exist yet, but there
will be commands added to the CLI so you can render the templates to see the files and
use your tools without Hash Core.

### Environments and targets

An environment is a special kind of resource, it does nothing when you build, test, publish, and deploy
it, but it can be used when running an action on a resource to provide the action with some **targets**
to run some actions.

Every time Hash Core wants to run an action on a resource in an environment, it will always first deploy
the environment resource, which probably includes deploying other resources which are defined as
dependencies in the environment's targets, but **what is a target?**

To understand targets let's try to talk about two actions on some resources.

The publish action of a docker image requires a docker registry to push the image to it, this registry
cannot be defined in every resource on its own, this will be a lot of work and repetition.

The deploy action of a Kustomize resource requires a k8s cluster to deploy to it, the same thing is true
here we cannot define access creds for this cluster on every Kustomize resource.

These two actions publish a docker image and deploy a Kustomize resource, need information from the environment
to be run, you probably want to deploy to the same registry in all environments, but probably want to deploy
to different clusters per environment, here come the targets.

A target is defined by an environment's resource, it is used by some actions in some resources so these actions
can be executed, two common targets are `DockerRegistry` which can be used to publish an image to a docker
registry and `K8STarget` which can be used to deploy to a Kubernetes cluster, these targets are used
by the resources which need them, if we try to deploy a Kustomize resource to an environment that doesn't have
a K8STarget, then the deploy will fail with a proper error message.

## Notable Hash Core features

Here we will list some of the most important hash features which will help you in managing your mono repositories

### Mutate resource specs using environments

When you deploy your resources to multiple environments, you want to have different values for their specs based on
the selected environment.

If you have a terraform resource, you can use the `variables` key in the specs to give the resource different values for
its variables and these values need to be different for every environment, to achieve this the terraform resource
is configured to only read the variables from its specs and not from anywhere else, but to give it different values
you can ask Hash Core to mutate the value for the resource's specs based on the selected environment, this can be
done using these keys in the environment's specs

```yaml
Terraform-gke:
    variables:
        gke_name: dev
        node_count: 3
```

This means that whenever we want to run any action on the resource with kind `Terraform` and name `gke` in this environment,
the variables in the resource's specs will be set to the values that we have here, and this happens automatically and in
memory only, so the action method in the resource can simply read the values and it will find the right values always.

If we used `Terraform` only in the key, then this mutation will be applied to all resources with the kind `Terraform` in this environment.

### Override actions

You can override how an action is run on a resource's instance by using `<action_name>_command` or `<action_name>_script`
in its specs, so when you execute the action on this resource hash core will execute this command or script instead, you can
also define pre- and post-actions for a single resource's instance using these keys `pre_<action_name>_command`, `pre_<action_name>_script`,
`post_<action_name>_command`, and `post_<action_name>_script`, a command takes precedence over a script if they are both defined.

When these commands or scripts are executed, you have access to these environment variables:

* `R_NAME` It contains the name of the resource.
* `R_PARENT` It contains the ID of the parent resource (Kind:Name). *not used now*
* `R_PARENT_NAME` It contains the name of the parent resource. *not used now*
* `R_ENV` It contains the name of the environment where the action is being executed.
* `R_ACTION` It contains the current name of the action being executed.
* `R_SPEC_{X}` this defines a group of environment variables for every spec element, for example,
    if you have a spec called 'x' with a value of 'abc' it will create an environment variable
    called R_SPEC_X with a value of 'abc'

### Define dependencies between resources

Your resources probably cannot live alone, they depend on other resources to be built, tested, published, or maybe deployed
in order, so you can run actions on them, if you use terraform to manage your infrastructure then you probably have
one config to create networks and another one to create the clusters in these networks, to express dependencies between
these two resources you can either use hash templates in your second resource to read the output from the network resource
that contains the network's ID, but sometimes dependencies cannot be expressed like this in templates, and you
need to add them explicitly using `depends_on` in the metadata of a resource, the depends_on is a list of objects, where
each object has this structure:

```YAML
id: Terraform:network
action1: build
action2: deploy
```

This means that to run action1 (build) on the current resource, you need first to run action2 (deploy) on the resource
with ID `Terraform:network`.

If either `action1` or `action2` are missing then they default to the current action being run.

### Read resource outputs in specs

When writing the specs for your resources, you can read outputs from other resources to be used in the
spec's value, this adds a dependency from this resource to another resource.

This is needed especially when writing targets for environments, look at this target definition

```YAML
- kind: DockerRegistryTarget
      name: docker
      spec:
        registry_url: $Terraform:shared-gcp-tf.deploy.registry_url.value
        service_account: $Terraform:shared-gcp-tf.deploy.repo_writer_email.value
```

In the values for `registry_url` and `service_account`, we're using outputs from other resources as can be
seen from the `$` sign, the first one means, to read the output called `registry_url` which results from running
action `deploy` on a resource with ID `Terraform:shared-gcp-tf`, we're taking the `.value` of the output
because terraform outputs are objects and `.value` contains the actual output's value, this is
the same format when you use `terraform outputs -json` command.

Whenever we want to publish a DockerImage resource to this environment, then this env is always deployed first
which depends on deploying the `Terraform:shared-gcp-tf` resource, this ensures always that the Docker Registry
is created first and we have the right URL and value for `service_account` used for authentication, if we ever
change the name of the registry which changes the `registry_url` output then all new docker images will be pushed
to this new registry.

## Conclusion

This was my introduction to Hash Core, this project is still in a testing phase, and I'll try to improve its features,
add new ones and test it for bugs and performance, you can find demos for using Hash Core in this [repository](https://gitlab.com/hash-platform/getting-started-demos).

More articles will be published about Hash Core in the next few months, I'm looking forward to your feedback and opinions,
you can always raise an issue [here](https://gitlab.com/hash-platform/hashkern/issues).

I hope you find the content useful for any comments or questions you can contact me
on my email address
[mouhsen.ibrahim@gmail.com](mailto:mouhsen.ibrahim@gmail.com?subject=add-hash-core-tutorial)

Stay tuned for more tutorials. :) :)
