---
layout: post
title:  "Git startup guide part 1"
date:   2017-08-26 00:12:00 +0300
categories: developer-tools
---

# Introduction
In this article we are going to **create a git repository on github** then learn how
to **clone** it, **create branches**, **checkout branches and merge** them effectively at the
end we will look at the basic ways to **undo our work** with git.

Before we start you might be wondering what is github?

# What is github?
Github is an online repository manager for git, with github you can create repositories,
share them with the world and show your work to other people, but github is more than this
and we will discover it in more detail later.

*Hint* There are other online repository managers such as [gitlab](https://gitlab.com/users/sign_in) and [bitbucket](https://bitbucket.org/).

## Create repositories on github
Before you create a repository on github you need to sign up to a github account and login
follow instructions on main github page [here](https://github.com) for more info.

If you already have a github account then you can create a new repository by clicking
on the plus icon next to your profile picture found in the upper right corner of the screen
and choosing **New repoitory** as shown in the following screen shot.
![github_new_repo]({{ site.url }}/assets/images/github_new_repo.jpg)

Now you can see the the new repository page where you will set your repository name,
Description, visibility and possibly add a README.md file and a .gitignore file with
a license.

This screen shot shows the new repository page:
![github_new_repo_form]({{ site.url }}/assets/images/github_new_repo_form.jpg)

Enter **test_repo** as the name, **Repo for testing git and github** as a description
and set the visibility to public and check **Initialize this repository with a README**
then click **Create repository**.

*Hint* If you wanted to create a private github repository then you must upgrade your
account to a commercial github account and pay money for that, for now we will use
public github repositories for free.
*Hint* Gitlab offers the ability to create unlimited number of private repositories
we will explore this later.
*Hint* a **.gitignore** file is a special file in git which is used to specify files
that you want git to ignore them completely and not show them as untracked files,
for example: compiled programs do not need to be version sourced only source files need,
more info about **.gitignore** later.

Once you have created the repository you will see the main page of the repo as shown
in this screen shot
![github_new_repo_page]({{ site.url }}/assets/images/github_test_repo_main.jpg)

You see the **README.md** file displayed by default, it is very important to include
this file in the root of your repo, it is the file which is viewed immediately by anyone
who enters your repo so take care of it to give a good first impression and encourage
visitors to explore your repo and maybe contribute to it or use it.

*Hint* the *.md* extension marks this file as a markdown file, more about markdown can be
found [here](https://en.wikipedia.org/wiki/Markdown) and [here](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet).

Now since we created our first github repository it is time to clone it to your local
machine and start working on it right away.
