---
layout: post
title: "REST API's are Crud"
date: 2013-04-02 01:35
comments: true
categories: web development
author: Allen Fair
header-img: images/transfer.jpg
---

[REST](http://en.wikipedia.org/wiki/Representational_state_transfer)
promotes CRUD. CRUD is for databases, not applications.

Databases generally have four operations to a set of data: Create, Read,
Update, and Delete; these four operations are known by the acronym CRUD. An
SQL-based relational database (like PostgreSQL, MySQL, etc.) have 4
cooresponding statements:

 * Insert -> Create
 * Select -> Read
 * Update -> Update
 * Delete -> Delete

The CouchDB database and SOLR search engine operate natively over a REST
interface. Your applications perform CRUD operations on these data
stores by employing the above style of request.

Architectures based on REST, like Ruby on Rails, builds the application
on table resources to perform CRUD operations. By doing this, we get a
free API into the application callable from any platform capable of
making HTTP/REST calls.

<!--more-->

## Crud As A Service

REST-based API's of this kind expose their
data structures, databases, naming, and relationships to the consumer.
This architecture adds a layer of business logic or intelligence onto
your database, but REST still maintains the database CRUD paradigm.
As a result, your application can become a "CRUD As A Service"
architecture.

Rails promotes this architecture from the top by defining REST-ful
Routes on each table-resource as the method of running your application,
and by extension your external API. A happy-path Rails app defines a
relational database table along with seven REST actions to operate on
it.

  * View: index, show
  * Form: new, edit (for user interfaces)
  * Change: create, update, destroy (delete)
  * Custom methods by HTTP Verb and collection/member specifications
  * Nested routes to manage has_many associations

Web interfaces based on this approach mimic the CRUD paradigm using what
I call the "Table Editor" pattern. Users navigate your application by
table, browsing lists of records, selecting records to edit, and firing
special actions from the relevant record. This is not the only way to
implement UI/UX, but Rails makes this easy to generate and implement.
Unfortunately, it is not a good pattern, and should be avoided.

For API's, these routes are the access pattern for your application.
The user interface can be changed to avoid
looking like a CRUD-based application, but your API remains a CRUD
interface.
Smaller applications where you have a simpler model or closer
logical/actual data structure may not be affected as much as larger or
more complex ones.

Rails uses the *ActiveResource* library to access a remote database,
service oriented architecture, or other CRUD-like data services. 
It is a REST/CRUD API client for a service that matches Rail's Restful
Routes.  For services that are meant to be integrated in this manner, 
having a CRUD service can be useful. 
Front-end Javascript MVC libraries like Backbone or Ember
use REST in a similar way to communicate with the back-end service.

## Expose Domain Objects, not Data Objects

When you write or use libraries, you work with an interface that
abstracts away the implementation details, and provides you with an
interface of the problem domain for you to understand and work with.

Why should your application interfaces be any different? Data is a
side-product of your Business or Problem Domain, not the solution to it.
We create OO systems that separate business needs from implementation
details.

This has been the call of the new voices in the Rails community.
People employ SOLID, SOA, DCI, Demeter, and other techniques--lessons 
from past OOP methodologies--to create better-crafted code.
We should also apply it to our external interfaces as well as our internal
ones.

Let's build applications around Domain Objects instead of data
objects; why should we use CRUD verb to interact with our application
instead of exposing a set of methods we would have on say, a service
object!


### Some User Interface Patterns

Users of Facebook don't have to go through table-based forms and lists
of records; the underlying data structures are never exposed to the
users. Our interfaces should be built the same way. The application
pages and routes should be designed for tasks instead of data models.
Here are a couple well-known interface types. (I'm no UX expert, and
these are the patterns that came to mind.)

Initially, show the state of the application to the user such as:

  * Dashboard
  * Activity Feed
  * Recent Work

From there, present tasks on these items as a pattern that hides the
CRUD and gathers the requirements for processing.

Dialog-Based Interface:

  * Forms do not map to any particular table or tables
  * Prompt user for the required fields
  * Shows defaults, allows user to specify other data
  * Display the result.
  * Client-Side tools pop-up forms for more data

Wizard Interface:

  * Steps though missing data forms
  * Builds underlaying data structures as it goes
  * Guides user over each decision along the way
  * Hmmm, sounds like Turbo Tax!



## A Possible Post-REST Routing Guide

An Object-Oriented programming interface is often better than a REST
one. Consider mapping your calls like an imperative or OO style call.

    Model.all(*args)
    GET /resource/ ? collection arguments...

    Model.find(id)
    GET /resource/id/view (edit, id=new, attribute)

    Model.find(id).association
    GET /resource/id/association ? collection args...

    Model.find(id).do_something(*args)
    POST /resource/id/method ? cols|method args

    Model.find(id).association.method(*args)
    POST /resrouce/id/association/method ? rows|method args

Remember, not all API users have the luxary of using an API client
written in their language of choice. Make is easier to use than
coercing their mindset into REST.

## Isn't this SOAP?

Perhaps. SOAP is a protocol, also over HTTP, but a more complex one. It is also more an OO approach much like
I have been describing. During research, I came across
[Principles of Service Design: Service Patterns and Anti-Patterns](http://msdn.microsoft.com/en-us/library/ms954638.aspx),
which describes "Anti-Pattern #1: CRUDy Interface."
The same warning exists in the SOAP world.

Was REST meant only to perform CRUD on data, like WebDAV? A resource is defined in the Wikipedia article on
[REST](http://en.wikipedia.org/wiki/Representational_state_transfer):

>  A resource can be essentially any coherent and meaningful concept that may be addressed. A representation of a resource is typically a document that captures the current or intended state of a resource.

Perhaps we can fit something in our domain into this concept. Does it
really matter? Can REST also be used to run a distributed method call
dispatch?

## Humane HTTP API Design

HTTP Protocols are limited, and once  you start using your own language
to define data operations, they become meaningless.

Not everyone is up to you standards. Have you ever worked with someone
trying to implement your REST API without being a developer? It's hard
for them to grasp, tweak and use. Their tool chains (possibly an
app with only a simple "URL callback") may not be as adept at calling your REST with
proper HTTP to regulate the transaction.

Also, parameter naming conventions can give users grief. Rail's
"model[attribute]" naming style may be simplified as "attribute" in a
lot of cases.

## Summary


Don't push your model REST/CRUD routes as your API. 
Consideration of your API users is as important as for your web
interface users.
Remove our CRUD interfaces, hide our implementation details,
and expose interfaces geared towards performing tasks instead of manipulating
databases.

REST is a great data protocol, but the HTTP methods are not as important
as the logical methods on your code. Design API's for people, not for
intermediate access protocols. 
