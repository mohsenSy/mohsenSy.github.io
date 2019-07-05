---
layout: post
title:  "What is DevOps?"
date:   2019-07-05 18:15:00 +0300
categories: sysadmin
summary: In this article I describe DevOps in my own opinion and based on my experience.
---

# Introduction

Hi friends, thanks for visiting my website and deciding to read this article, here I will put
my opinion and use my personal experience to describe DevOps one of the wrongly used concepts
these days in the field of Software Engineering and Delivery, let me start with this joke
that I heard in a video talking about DevOps:

"If you bring 10 Computer Science Scientists, put them in a room and ask to define DevOps
you will get 11 different definitions of DevOps" :)

So why 11 and we only have 10 scientists? Well if you ask me to define DevOps today and do
the same tomorrow I might give you two different ones but the main concepts are the same
and this is what we will study here and help understand them and use DevOps in your organization.


# What is not DevOps?
To make it easier to learn about DevOps we will start with what DevOps is not?
* DevOps is not a product that you can buy from any one or any company, if you decide
  to bring DevOps to your organization you cannot go and buy it from any store.
* DevOps is not a set of practices or steps that you must follow to bring it to your organization.
* DevOps is not solely a physical or mental concept that you can use in your organization but a
  combination of both you will learn more about this in the following sections.

The term DevOps was first coined by [Patrick Debois](https://newrelic.com/devops/what-is-devops) in 2009 to describe the importance of collaboration
between **Devs** and **Ops** in any organization to deliver **value to end users** more **rapidly**.

I highlighted the most important words in the last sentence about DevOps so let us talk about them now.

# Devs and Ops
Let us start by decoupling the word DevOps, this term consists of the combination of first three letters
from two words Developers and Operations.

Developers are the **people** who work on writing code and developing our applications and tools used to build
our products and Operations are the **people** who work to deploy these products to servers and networks
to become accessible by our clients all over the world, without Developers our servers are networks would just
be a big junk of hardware that does nothing and without Operations the products created by our Developers will
not leave their own work stations and will not be used by our clients at all.

This is where DevOps started, we need to value the roles of all of our people in the process of making our
products and making them available to the whole world, DevOps embraces the collaboration between Developers
and Operations to bring us faster and closer to our clients, it also makes everyone responsible for the Delivery
of value to end users.

Of course we also have many other departments including Marketing teams, Quality Assurance teams, managers and directors
and many more but here we focused on Developers and Operations because they are mentioned in the term DevOps, all of these
people any many more need to work together as a team for the benefit of the organization they work in.

# Value not products
In the last section I used the term product when talking about what Developers make and the term value when
talking about what is delivered to end users, I meant to use these two terms like this intentionally.

Developers create products like we said but what end users need is not the product only the value delivered
with the product that what really matters, these days there are many products around the world of similar types
many search engines, many programming languages and frameworks, many jobs sites, etc....

How will users choose between all of them? They will look for the product that gives them the best value, when they
need to compare two products its features, price, weak and strong points, uses will be taken into account to make
a final decision about what will be used.

So DevOps focuses on this concept and encourages Developers to create high value products and also take
end user feedback seriously when modifying their products and adding new features to deliver the best value
to our end users.

# Rapid Development
Here we are talking about Time to Market, we want our products to make it quickly to the market but not
so quick, full of bugs and lack some features, so how do we achieve this?

DevOps adopts concepts to help get our products to market easily and quickly such as Automation, testing,
Continuous Integration, Delivery and Deployment, monitoring etc...., we will talk about all these in
next sections.

Adopting DevOps helps us get to the market faster in the first launch and also make updates faster and cleaner
with no or minimal downtime, our products will not just stay as they were launched first, we need to update them
from time to time and when we use DevOps concepts right especially automation, testing and Continuous Deployment
we will be able to update them a lot easily and with no to minimal downtime during the updates.

Teams adopting DevOps are expected to update their products multiple times a day in contrast with teams not adopting
DevOps they might update once a month or 3 to 6 months, which makes fixing bugs and adding new features a very slow
process and users have to wait a long time to get bugs fixed and new features added.

# Mental side of DevOps
In the last sections we talked about DevOps mental side, how we should think when implementing DevOps, Devs and
Ops need to collaborate and are a single team, we need to deliver value to end users, we must adopt rapid development
concepts to get to the market quickly and be able to update our apps without downtime with multiple times a day.

The most important of all of these are the people who work in the organization and the end users, DevOps makes sure
that all Developers and Operations are working closely on the same page with other departments and with each other
and also be close to end users through feedback loops that help shape the future of our products to deliver more
value to clients.

We need to focus on these concepts before moving along to the tools that help us achieve all of this.

Hint: A common mistake by organizations who try to adopt DevOps is that they start with using the DevOps tool chain
before completing the change of mentality among their people (Devs, Ops, Marketing, Directors, testers etc...),
this is a very wrong approach and it will lead to tools used wrongly by people or maybe not used at all, this will
give negative effects to the organization, so first make sure you have people mentally ready for DevOps and then
start using DevOps tools.

Now we need to talk about some practices for implementing DevOps and achieving what we already mentioned.

# Automation
Automation is key to DevOps success we talked about Rapid Development and the ability to deploy updates quickly
and without downtime we can do all of this with automation.

To automate something first you need to be able to do it manually, so practice first using test servers, deploy
apps to them, create database clusters, run monitoring software etc... and then move to automating all of this.

Automation does not include only configuring existing servers and deploying apps but also provisioning new servers
and resources for our apps to function properly.

For automation I use [ansible](https://ansible.com) to describe the state of our servers and resources using
YAML files and then apply this state to them whenever we create a change.

For provisioning new servers [terraform](https://www.terraform.io/) can be used, however I did not use yet but planning to do so.

There is a big advantage to using automation in regards to helping Developers adopt DevOps, the state
of servers is now described using code and this code can be committed to source control and changed by anyone
then these changes will be deployed to our servers and Developers love to work with code, that is their job
actually and by being able to configure servers using code and not log in to SSH sessions this gives them
a great advantage also they can easily replicate production environment using code and test their apps against
these production-like environments before going to production.

# Testing
With automation it becomes easier to deploy updates to our products but we need to make sure
these updates do not include any security holes, bugs or causes existing features not to work
properly, to achieve this we need to always test our code before moving it to production.

The code we want to test does not only include our applications' code but also the code that
configures our servers, as we have seen in the last section we now use code such as playbooks
in ansible to configure our servers, so when we make changes these changes must be tested
before being deployed to production.

To do testing of our apps we can use a testing library according to the programming language and framework we are
using for example [unittest](https://docs.python.org/3/library/unittest.html) is good for Python apps, we can use
[selenium](https://www.seleniumhq.org) for testing our apps in a real browser, [jest](https://jestjs.io) for testing client side JavaScript
and [molecule](https://molecule.readthedocs.io/en/stable/) for testing ansible roles, [testinfra](https://testinfra.readthedocs.io/en/latest/) for
testing our changes to servers using ansible.
# Continuous Integration and Deployment
Okay we talked about Automation and Testing but how do we run them? Manually with every change? Or using a special tool for that?

Of course we cannot do this manually because this includes a lot of work, we could forget to run tests before
deploying to production and also we could have many parallel environments one for review, staging, QA etc...
and we cannot manually deploy to all of these manually so here comes the tools for Continuous Integration and Deployment.

Continuous Integration encourages Developers to push their code early to source control so it will be deployed
to a review environment and other Developers or team leaders can see the code and make comments about it, when
these new changes are ready they are deployed to a staging environment to be further tested after being merged with
the master branch which includes latest development after these changes are tested they can be deployed to production
environment where our end users will see them.

Continuous Deployment encourages to deploy multiple times a day and defines the right steps for deploying
updates to our apss, we can use [ansible](https://ansible.com) to do the Deployment but we can also use
other special tools such as [capistrano](https://github.com/capistrano/capistrano) to do the job.

The tools used to do Continuous Integration are [gitlab CI](https://about.gitlab.com/product/continuous-integration/),
[travic CI](https://travis-ci.org) and [jenkins](https://jenkins.io), I prefer to use gitlab CI.
# Conclusion
In this article I gave my own personal opinion about DevOps based on my four years experience as Linux
Systems Administrator, every thing mentioned here was based on my work and the problems I encountered
I did not implement all of the concepts I talked about them in here but looking forward to work on them
and write similar articles and tutorials after this one.

Just to remind you make sure you change the mentality of your organization to accept and adopt DevOps
practices before working on any tools used in DevOps, this is key to success in the adoption process.

I hope you find the content useful for any comments or questions you can contact me
on my email address [mohsen47@hotmail.co.uk](mailto:mohsen47@hotmail.co.uk?subject=what-is-devops)

Stay tuned for more articles. :) :)
