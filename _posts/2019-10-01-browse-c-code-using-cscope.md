---
layout: post
title:  "Browse C code using cscope"
date:   2019-10-01 00:53:00 +0300
categories: programming
summary: In this tutorial you will learn how to browse C/C++ code effectively using cscope
---

# Introduction
Sometimes we have an open source application or system written in C/C++ that we want to contribute to, we try
to understand the structure of the application by searching for the main function and following the function
calls one by one to learn how the application work, in our search we need to find some functions or declarations
in the files so we can inspect their code and their uses, we need to know which header files are included and where?
We need to find out where functions are called and by which functions? We need to search for a string or regex pattern
in the files, to do these tasks and more we can use [cscope](http://cscope.sourceforge.net).

cscope is an old but still effective tool to browse C/C++ code and learn about the structure of the code by following
function calls.

In this short tutorial we will learn how to install and use cscope to browse header files found in Linux distributions
in the path `/usr/include`.

# Installation
cscope can be installed easily on Debian based distributions using this command
```
sudo apt-get install -y cscope
```

To make sure that cscope is installed correctly check its version with this command
```
cscope --version
```

# Prepare cscope database
cscope creates its own database to store parsed source code in it and use the database when searching for functions, declarations
and anything in the source code, to generate a database for the Linux header files use these commands

```
cd /usr/include
sudo su
find . -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" > cscope.files
cscope -q -R -b -i cscope.files
```

The first command changes directory to `/usr/include`, the seocnd one switches to root user.

In order for cscope to work properly it needs to find the names of files to use them as source files,
this is the job of the third command, it uses standard Linux find command to find all files whose names end in .c,
.h, .cpp or .hpp extension and writes their paths to `cscope.files` file.

The last command uses file names found in `cscope.files` file and creates the cscope database  which is stored in
three files in current directory, their names are `cscope.out`, `cscope.out` and `cscope.in.out`, these files are
used to store cscope database where the information need by cscope to search source files are located.

# Usage
Before we start using cscope, wen need to know that cscope uses vim text editor by default to open source files
you can change this editor to `nano` with this command
```
export CSCOPE_EDITOR=`which nano`
```
Add this to command to `~/.bashrc` to make the change permanent.
Issue this command to open cscope text-based browser
```
cscope -d
```

You will get something like this on the terminal screen
```
Find this C symbol:
Find this global definition:
Find functions called by this function:
Find functions calling this function:
Find this text string:
Change this text string:
Find this egrep pattern:
Find this file:
Find files #including this file:
Find assignments to this symbol:
```

These are the tasks you can do with cscope, let us try to use them one by one

* Find this C symbol: This helps you to find symbols in C/C++ language, a symbol can be anything from a variable, function, type etc...
  for example type `open` and press `enter` you will get many results, use `space` to go to next results page and press `enter` when
  you select the file `fcntl.h` this will open the file using `nano` with the pointer at the declaration of the function open.
* Find this global definition: This is the same as the previous one, except that it only searches in global namespace for names.
* Find functions called by this function: This will find all function that are called by the function specified.
* Find functions calling this function: This helps you to check when this function is called and by any functions.
* Find this text string: This helps to search for a specific text in the source code.
* Change this text string: This help to change some text in all the source files.
* Find this egrep pattern: This helps to search all files using a regular expression.
* Find this file: Here we can find files by name.
* Find files #including this file: This helps to find which files include a specific header file.
* Find assignments to this symbol: This can help you to know all values that a symbol holds in the source code.

To move from results page to commands table use `tab` key, to exit cscope browser use `CTRL+D`.

Now try to find the declaration of the famous printf function.

# Conclusion
Here we learned about cscope and how it can be used to browse large C/C++ projects, I hope it will help you
in your work on C/C++ projects and contribute to open source applications.


I hope you find the content useful for any comments or questions you can contact me
on my email address [mohsen47@hotmail.co.uk](mailto:mohsen47@hotmail.co.uk?subject=browse-c-code-using-cscope)

Stay tuned for more articles. :) :)
