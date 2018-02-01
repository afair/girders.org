---
layout: post
title: "Setup Rails 4.1, Spring, Rspec, and Guard"
date: 2014-02-06 10:38
comments: true
categories: rails
author: Allen Fair
header-img: images/transfer.jpg
---

Rails 4.1 allows us to use [Spring](https://github.com/rails/spring)
to run our `rails` and `rake` commands quickly by running your
application in the background and avoiding the rails startup time
penalty. It took me a little while to find this information, so here is my
guide to setting this up.

I'm using the [Rspec](http://rspec.info/)
testing framework with the [Guard](https://github.com/guard/guard)
event watcher as the test runner. Spring allows us to watch the test run
almost immediately after hitting save of a file in the editor.

<!--more-->

First, let's start with a fresh app to understand things. Upgrading an
existing app is straightforward with this technique as well. Note that I
am using Rails 4.1.0.beta1 on Ruby 2.1.0p0.

```
% rails new myapp -T
% cd myapp
% vim Gemfile
```

After we open the `Gemfile` in our editor, we add the following gems:

  * [rspec-rails](http://rubygems.org/gems/rspec-rails) - The
    RSpec testing framework with Rails integrations
  * [spring-commands-rspec](http://rubygems.org/gems/spring-commands-rspec) - Adds rspec command for spring.
    Includes a dependency for the [spring](http://rubygems.org/gems/spring) Rails application preloader.
  * [guard-rspec](http://rubygems.org/gems/guard-rspec) - The Guard
    file watcher for running rspec
  * [rb-fsevent](http://rubygems.org/gems/rb-fsevent) - For OS/X only,
    waits for file changes from the Mac OS/X FSEvents API instead of
    polling the disk for changes.

Add this block to the `Gemfile` (You may wish to add gem versions as
well.)

```ruby
group :development, :test do
  gem 'spring-commands-rspec'
  gem 'rspec-rails'
  gem 'guard-rspec'
  gem 'rb-fsevent' if `uname` =~ /Darwin/
end
```

"Bundle" again after saving to install the dependent gems.

```
% bundle install
```

## Setup Spring

The `spring` command runs a command through the spring application
runner. By default, it is configured to run `rails` and `rake` commands
only. We added a plugin gem to allow it to run `rspec` for us.


Spring has a `binstub` subcommand that updates the scripts in `myapp/bin`
to load the spring runner. Run this command to configure these scripts
(when converting to spring) and for the rspec command.

```
% spring binstub --all
* bin/rake: spring already present
* bin/rspec: generated with spring
* bin/rails: spring already present
```

You can check if spring has your application running as a background
process with the status subcommand. When you run a spring-enabled
command, it will start the server.

The startup for the first time will take a moment as rails initializes.
Now that spring has started the app server for you, subsequent runs will
use a forked process from this server instead and return faster.

```
% spring status
Spring is not running.
% rails g
...
% spring status
Spring is running:

89168 spring server | myapp | started 5 secs ago
89170 spring app    | myapp | started 5 secs ago | development mode
```

The spring server will shutdown automatically when your shell session is
closed. You can shut it down yourself by:

```
% spring stop
Spring stopped.
```

That's about all you need to know to get started with spring.

## Setting up Rspec and Guard

This process is the same as you normally would do:

```
% rails g rspec:install
      create  .rspec
      create  spec
      create  spec/spec_helper.rb
% guard init
11:32:14 - INFO - Writing new Guardfile to /Users/allen/src/myapp/Guardfile
11:32:14 - INFO - rspec guard added to Guardfile, feel free to edit it
% vim Guardfile
```

This sets up the files for rspec and guard. Now we have to tell guard to
use the spring runner when using rspec. Edit your `Guardfile` and change
the command for rspec to `spring rspec`. Change this line:

```
guard :rspec do
```

to 

```
guard :rspec, cmd:"spring rspec" do
```

## Running 

(Running with binstubs, shell extensions, alias, etc. may make executing
these commands different on your system. You may need to `bundle exec
rails` or `bin/rails`, or however your environment is setup.)

Check out the time gains running rspec through spring, I'll use the time
command:

```
% time spring rspec
...
spring rspec  0.12s user 0.07s system 6% cpu 3.126 total

% time spring rspec
...
spring rspec  0.12s user 0.06s system 30% cpu 0.600 total
```

This is on a minimal app with a single, scaffolded resource. As your app
grows larger, the initial startup time will be longer, and your time
savings will multiply accordingly.  (Of course, you can just run the 
`spring rspec` command if you are more
interested in the results rather than the timings.)

To start TDD'ing, fire up guard in a terminal session.

```
% guard
11:48:02 - INFO - Guard is using TerminalTitle to send notifications.
11:48:02 - INFO - Guard::RSpec is running
11:48:02 - INFO - Guard is now watching at '/Users/allen/src/myapp'
[1] guard(main)>
```

This runs `guard` to watch your app files and kicks off the `spring
rspec` command to run your changed spec file or suite.

If you need to change something basic in your app, such as adding a gem,
updating a local dependency that could be cached, you need to restart
both guard (Ctrl-D at the console) (or a server or console process), 
and spring (`spring stop`). Restarting
`guard` will restart spring as well, with your dependencies reloaded.
