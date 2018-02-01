---
layout: default
title: Rails 3.1 Application Architecture
author: Allen Fair
header-img: images/transfer.jpg
---
# Architecting a Rails 3.1 App

    $ gem install rails [--pre]
    $ rails new bug -d postgresql 

Options to consider:

    -d <database> : Database to use
    -T  : Skip Test Unit, if you want to use RSpec, etc.
    -j <library> : Set up with the Javascript library
    -J  : Skip Javascript library
    -O  : Skip active-record

[Ruby Toolbox](http://ruby-toolbox.com/) is a good place to look for common rails plugins and gems to add functionality for your project. Here are the ones I like to consider.

[Rails Wizard](http://railswizard.org/) is a cool tool to generate a rails template, automatically installing the tools you select. When you are done, just run the `rails` command it gives you.
    rails new APP_NAME -m http://railswizard.org/5af13000c1b677a4453a.rb
If you want to apply this template to an existing application, you can do:
    rake rails:template http://railswizard.org/5af13000c1b677a4453a.rb

[Rubygems](http://rubygems.org/) is the starting point to search for these gems. I have copied many gem descriptions into this page directly from their rubygems page.

## IRB & Environment

These gems are useful in your RVM `global` namespace, which is shared across projects. Of course, you can add them directly to your `Gemfile` and have them available for everyone.

[Awesome Print](http://rubygems.org/gems/awesome_print): `irb` extension to pretty print Ruby objects to visualize their structure.

[Wirble](http://pablotron.org/software/wirble/): is a set of enhancements for `irb`,  including tab-completion, history, and a built-in ri command, as well as colorized results and a couple other goodies.

[Hirb](http://rubygems.org/gems/hirb): improves output for inspect output.

[Nifty Generators](http://rubygems.org/gems/nifty-generators): is Ryan Bate's collection of generators for layouts and scaffolding.

Gemfile:
    group :development do
      gem 'awesome_print'
      gem 'wirble'
      gem 'hirb'
      gem 'ruby-debug19'
      gem 'nifty-generators'
    end

irbrc or ~/.irbrc:
    require 'rubygems'
    require 'wirble'
    require 'awesome_print'
    # start wirble (with color)
    Wirble.init
    Wirble.colorize
		

## Views

### HAML
[HAML](http://rubygems.org/gems/haml): Templating Language. For rails, use the [haml-rails](http://rubygems.org/gems/haml-rails) gem instead:
    gem "haml-rails"

### Formtastic
[Formtastic](http://rubygems.org/gems/formtastic): Rails form builder plugin/gem with semantically rich and accessible markup. Also install the [validation_reflection](http://rubygems.org/gems/validation_reflection) gem to build in your required validations into the form. A good getting started document is on the [github page](https://github.com/justinfrench/formtastic).

Gemfile:
    gem "formtastic"
		gem "validation_reflection"
Shell:
    rails generate formtastic:install
This generates the configuration file at `config/initializers/formtastic.rb`.

Add the stylesheet to the head section of `views/layouts/application.html.*`:

    <%= stylesheet_link_tag 'formtastic', 'formtastic_changes' %>

Generate forms for the model, overwrites app/views/*/_form.html.*
   rails generate formtastic:form Post --haml 

### Simple Navigation
[Simple Navigation](http://rubygems.org/gems/simple-navigation): A ruby gem for creating navigations (with multiple levels) for your Rails2, Rails3, Sinatra or Padrino applications. Render your navigation as html list, link list or breadcrumbs. See the [examples](http://simple-navigation-demo.andischacke.com/) for demonstrations and stylsheets.

Gemfile:
    gem "simple-navigation"

## Layouts and Assets
### Blueprint Rails
[Blueprint Rails](http://rubygems.org/gems/blueprint-rails): Installs the [Blueprint CSS Framework](http://www.blueprintcss.org/) in your app as a nice starting point for a clean look and customizable grid.

Gemfile:
    gem "blueprint-rails"
Follow the setup instructions at the [github page](https://github.com/joshuaclayton/blueprint-css). 

### Compass
[Compass](http://rubygems.org/gems/compass): a Sass-based Stylesheet Framework that streamlines the creation and maintainance of CSS.

Gemfile:
    gem 'compass'
Setup:
    compass init rails /path/to/railsroot

### CSS3 Buttons
[CSS3 Buttons](http://rubygems.org/gems/css3buttons): Rails helper methods and generators for the css3buttons by Michael Henriksen. This is a clean, github-like button look.

Gemfile:
    gem 'css3buttons'
Shell:
    rails c css3buttons
Add the stylesheet to the layout file:
    <%= css3buttons_stylesheets %>
Usage:
    <%= button_link_to "Search", search_path %>

### Nifty Generators Layout
Nifty Generators Layout Installation:
    rails g nifty:layout --help

## Authentication and Authorization
### Devise
[Devise](http://rubygems.org/gems/devise): Flexible authentication solution for Rails with Warden

Gemfile:
    gem 'devise'
Generate and devise engine, and edit the files to enable specific features, and finally migrate the database. See the [devise github page](https://github.com/plataformatec/devise) for more information.
    rails generate devise:install
    rails generate devise User
    edit app/models/user.rb db/migrate/*devise_create_users*
    rake db:migrate
Add to config/routes.tb
    devise_for :users

### Omniauth
[Onmuauth](http://rubygems.org/gems/omniauth): an authentication framework that that separates the concept of authentiation from the concept of identity, providing simple hooks for any application to have one or multiple authentication providers for a user. See more at the [omniauth homepage](https://github.com/intridea/omniauth).

Gemfile:
    gem "omniauth"

### Cancan
[Cancan](http://rubygems.org/gems/cancan): Simple authorization solution for Rails which is decoupled from user roles. All permissions are stored in a single location. Read the [cancan githug page](https://github.com/ryanb/cancan) for more usage information.

Gemfile:
    gem 'cancan'
Generate:
    rails g cancan:ability



## Active Record Extensions 
### Kaminari
[Kaminari](http://rubygems.org/gems/kaminari): a Scope & Engine based, clean, powerful, customizable and sophisticated paginator for Rails 3. The [homepage](https://github.com/amatsuda/kaminari) has more details.

Gemfile:
    gem "kaminari"

Generation:
    rails g kaminari:config

Controller Usage:
    User.page(7).per(50)

Pagination control in the View:
    <%= paginate @users, :window => 2 %>

[]():
[]():

## API
### Grape
[Grape](http://rubygems.org/gems/grape): A Ruby framework for rapid API development with great conventions. [Homepage](https://github.com/intridea/grape).

Gemfile:
    gem "grape"

## Search
### Sunspot
[Sunspot](http://rubygems.org/gems/sunspot): Sunspot is a library providing a powerful, all-ruby API for the Solr search engine. Sunspot manages the configuration of persistent Ruby classes for search and indexing and exposes Solr's most powerful features through a collection of DSLs. Complex search operations can be performed without hand-writing any boolean queries or building Solr parameters by hand. Instructions on [github](https://github.com/outoftime/sunspot).

### Thinking Sphinx
[Thinking Sphinx](http://rubygems.org/gems/thinking-sphinx): A concise and easy-to-use Ruby library that connects ActiveRecord to the Sphinx search daemon, managing configuration, indexing and searching. Instructions for [sphinx on rails 3](http://freelancing-god.github.com/ts/en/rails3.html).

## Presenters
### Apotomo
[Apotomo](http://rubygems.org/gems/apotomo): [github](https://github.com/apotonick/apotomo).

## Testing
### Rspec
[Rspec](http://rubygems.org/gems/rspec): BDD for ruby. [github](https://github.com/rspec/rspec-rails).

### Cucumber
[Cucumber](http://rubygems.org/gems/cucumber): [Homepage](http://cukes.info/).

### Capybara
[Capybara](http://rubygems.org/gems/capybara): Capybara is an integration testing tool for rack based web applications. It simulates how a user would interact with a website. [github](https://github.com/jnicklas/capybara)

### ZenTest
[ZenTest](http://rubygems.org/gems/ZenTest): ZenTest provides 4 different tools: zentest, unit_diff, autotest, and multiruby. ZenTest scans your target and unit-test code and writes your missing code based on simple naming rules, enabling XP at a much quicker pace. ZenTest only works with Ruby and Test::Unit. Nobody uses this tool anymore but it is the package namesake, so it stays. unit_diff is a command-line filter to diff expected results from actual results and allow you to quickly see exactly what is wrong. autotest is a continous testing facility meant to be used during development. As soon as you save a file, autotest will run the corresponding dependent tests. multiruby runs anything you want on multiple versions of ruby. Great for compatibility checking! Use multiruby_setup to manage your installed versions.

### Guard
[Guard](http://rubygems.org/gems/guard): [github](https://github.com/guard/guard).
[Railscast episode](http://railscasts.com/episodes/264-guard).


### Install your testing tools

Gemfile:
	group :test, :development do
	 	gem 'turn', :require=>false
  	gem "rspec-rails" #, "~> 2.4"
		gem "webrat"
		gem 'cucumber-rails'
    gem 'database_cleaner'
		gem 'rb-fsevent', :require => false if RUBY_PLATFORM =~ /darwin/i
    gem 'guard-rspec'
		gem 'guard-livereload'
		gem 'guard-cucumber'
	end

Generate: 
	rails generate rspec:install
	rails generate cucumber:install
	guard init rspec
	guard init cucumber
	guard init livereload
	vim Guardfile
	guard

