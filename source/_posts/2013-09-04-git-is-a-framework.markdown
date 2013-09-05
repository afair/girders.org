---
layout: post
title: "Git is a framework for creating a Version Control System"
date: 2013-09-04 22:24
comments: true
categories: 
---
__TL;DR__ - Git is a low-level library.  All development and deployment
environments differ, so build your own development work
flow system on top of git to build your best work flow environment.

The git version control system became hugely popular once it was
introduced, and along with [Github](http://github.com), achieved a
dominant role in open source to enterprise development.

Git is powerful, even complicated, but also allows a novice to start
with minimal training. The more I use git, the more I start finding odd
corners that I need to head to google to find out more how to use it.
There are some parts of it that are just darn incomprehensible unless
you understand the internals, so it becomes hard to guess where to look
to find your answers.

The .gitconfig file allows you to customize git, adding default flags,
abbreviations, etc., to help you build up your work flow. 

Github adds a layer on top git with pull requests, issues, and more.
Their "hub" package enhances git to smooth over some cruftiness and
integrate command line git with their service.

The [git-flow](https://github.com/nvie/gitflow) package also adds a
convention of work flow and best practices for a team using git.

All these tools point to the fact that git doesn't fit every need. Each
team, organization, deployment practice and scenario require a unique
requirement for a version control system. 

You need to determine your own requirements and build a version control
system, based on git (or really, any other). You can integrate
development, review, deployment, billing, issues, testing, continuous
integration, or whatever, into a single point of control and procedure.

For single-developer projects, perhaps a well-crafed .gitconfig is all
you need. You can even extend the git command by adding subcommands that
execute multiple git commands or any other system command.

For a small team, perhaps a shell script or app can usher change through
proper channels. Perhaps you find that off-the-shelf solutions like
git-flow fit well enough.

Before you start, you need to work it manually for a while to understand
the pain points of your situation, and find the solutions that solve
them, or enhance how you currently operate.

Every shop needs a serious git advocate on staff, who can answer those
edge questions like "how do I delete a remote branch?" to "where did my
commit go?" Like any other piece of software, you have to know why it
works, and how it's implemented so when things go awry, you can get back
on your feet in no time.
