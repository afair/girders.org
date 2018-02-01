---
layout: post
title: "Building Rails API's with JSONAPI and JSONAPI-Resources"
date: 2016-08-26 10:36
comments: true
author: Allen Fair
header-img: images/transfer.jpg
---

Sooner or later, every application needs an API.
It will need to integrate with your microservices, peer client service,
or your new front-end mobile and web apps. With
[JSONAPI](http://jsonapi.org), and
[JSONAPI-Resources](https://github.com/cerebris/jsonapi-resources),
building your API platform is easy. You just add your own
application magic. Along with one of these
[JSONAPI Client Libraries](http://jsonapi.org/implementations/#client-libraries),
your application can rule the world.

There is a lot of background that I won't be covering. I'll assume you
are familiar with
[HTTP](https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol),
[REST](https://en.wikipedia.org/wiki/Representational_state_transfer),
[JSON](https://en.wikipedia.org/wiki/JSON),
[Rails Routing](http://guides.rubyonrails.org/routing.html),
and have some basic [Rails](http://rubyonrails.org/) experience.
I'm writing the overview I wish I had when I started.
Not all examples are complete or polished, but should be far enough
along so you can "load" the problem into your head when starting work
on your API.

<!--more-->

## Install & Setup

Create your rails application if don't have one.
If your new app will be API-Only (no HTML pages rendered), use
the `--api` option to pare down the libraries Rails won't need.

Add the `jsonapi-resources` gem to your Gemfile and run the `bundle
install` command to pull it in. I'll refer to jsonapi-resources as
**JR** from now on.

What is a resource? Usually, we think of resources as a term used in
[REST](https://en.wikipedia.org/wiki/Representational_state_transfer)
web apps matching the data model or underlying database table.
This isn't always the case. They can also refer to a service that
performs and action or return data that is a composite view of your
data. Each resource has its own URL or "endpoint" which responds to
requests on that resource.

JR provides two rails generators to build out your resource.
It saves a little typing, but doesn't provide anything special.
You'll need one of each to put the resource online.

* *jsonapi:resource* generates an empty resource definition file in
  `app/resources/xxxxxx_resource.rb`
* *jsonapi:controller* generates an empty resource controller
  definition file in `app/controllers/xxxxxx_resource.rb`.

In your routes file, use the `jsonapi_resources :resource_name`
helper to build routes for the resource.

## JSONAPI Requests

Now we have the tools we need, so next we need to understand how JSONAPI
works. We need to first plan out how our API URL's will look like.
Let's break this down.

## Dreaming in URL's

We'll put the API URL's into its own namespace. This lets our web server
identify API requests to perform special processing, like sending them
to a separate application instance or rate limiting.

Also, we'll need to version our API to designate breaking changes.
JSONAPI guarantees that future changes must be backwards compatible with
existing services, but our application may need to evolve beyond what we
do now. Conventionally, tags like "v1", "v2", etc. are used
to identify the version. There are multiple methods of versioning, such
as adding it to your `Content-Type` or other header, but putting it in
the URL is the simplest for our application structure. Each version
becomes a namespace on top of the API namespace.

    https://example.com/api/v1/

Each resource name is an endpoint in this namespace. Resources should
not be nested in JSONAPI, and instead are more like Rails'
[shallow nesting](http://guides.rubyonrails.org/routing.html). The URL
endpoints will look like this:

    https://example.com/api/v1/posts
    https://example.com/api/v1/posts/123
    https://example.com/api/v1/posts/123/relationships/comments
    https://example.com/api/v1/comments/456

### Fetch (GET) Requests

The JSONAPI standard provides query string parameters for filtering,
pagination, sorting, sparse fieldsets (limiting attributes returned),
and including related resources (parent, children, or related objects).

A nearly complete example request using these features follows. I'll
format across multiple lines for easy reading, but the URL and query
string consists of a single string sent via HTTP. Also, I won't be
[percent encoding](https://en.wikipedia.org/wiki/Percent-encoding)
these URL examples as required.

    GET https://example.com/api/v1/posts
        ?page[number]=2
        &page[size]=50
        &sort=author,-created
        &fields[posts]=id,title,created
        &include=comments,author
        &filter[posts]=1,2
        &filter[comments]=1,2
        &filter[status]=posted

The specification doesn't cover the details of pagination and filtering,
leaving that decision up to the library implementation and application,
but does provide these examples on how these are expected to be used.
This usage reflects the JR basic implementation.

* **page[]** - Pagination parameters can be offset or page numbering.
  This is library and application defined. We will use page numbers here.
    * "number" - The page number
    * "size" - The number of records expected per page
* **sort** - A string of comma-separated field names. Descending sort
  order uses a "-" (hyphen) prefix to the field name.
* **fields[resource]** - Specify the resource name in the brackets, and the value
  is a comma-separated list of attributes from the resource.
* **include** - a comma-separated list of related resources to return with
  the base data.
* **filter[]** - When a resource name is given, the value is a
  comma-separated list of id's. When a field name is given, the value is
  a comma-separated list(?) of values. Filters provide a data scoping
  and search mechanism.
* The **/relationships/comments** part of the URL will only return a list
  of related id's. To get the full attributes returned as well, use the
  "include=comments" parameter (where "comments" is the name of the
  relationship".

Check out the full details on the
[JSONAPI Specification](http://jsonapi.org/format/) page.

### JSONAPI POST and PATCH Request

POST (create) and PATCH (update) requests require a payload body of JSON
in the JSONAPI format. This is a JSON object with key:

* **data** - the resource object being created (see below).
* **relationships** - a hash of resource names and resource objects for
related records being created, similar to Rails' nested forms and
[accepts\_nested\_attributes\_for](http://api.rubyonrails.org/classes/ActiveRecord/NestedAttributes/ClassMethods.html#method-i-accepts_nested_attributes_for).

A **resource object** is a JSON object (hash) with the keys:

* **type** - The name of the resource.
* **id** - The id of the resource being updated. Not used for create.
* **attributes** - A hash of attribute names and values.

```json
    {
      "data": {
        "type": "photos",
        "attributes": {
          "title": "Ember Hamster",
          "src": "http://example.com/images/productivity.png"
        },
        "relationships": {
          "photographer": {
            "data": { "type": "people", "id": "9" }
          }
        }
      }
    }
```

### JSONAPI Delete Request

DELETE is the simplest request. Give it a record endpoint with an id.

    DELETE /api/v1/posts/1

I can't find any more information on deleting all records or using a
filter parameter to the delete request to delete a list of records. That
could be nice if you can do something like:

    DELETE /api/v1/posts?filter[author]=1,2,3 /* Not real */

### JSONAPI HTTP Request

JSONAPI has its own
[MIME Type](https://en.wikipedia.org/wiki/Media_type)
that must be sent on the `Accept` and `Content-Type` (when sending data)
HTTP Headers. The HTTP Request could look like this:

    GET /api/v1/posts?page[number]=2 HTTP/1.1
    Accept: application/vnd.api+json

    POST /api/v1/posts HTTP/1.1
    Accept: application/vnd.api+json
    Content-Type: application/vnd.api+json

    {"data":{"type":"posts","attributes":{...}}}

## JSONAPI Response

The HTTP Response is a JSON document returned with the JSONAPI Mime
Type. The HTTP Status Code is also important, and can also be found in
the "errors" section when an error occurred.

    HTTP/1.1 200 OK
    Content-Type: application/vnd.api+json

    {"data":{"type":"posts","attributes":{...}}}

The JSONAPI Response data structure has the following structure:

    links: {self: url, next: url, last: url, related: url, ...}
    data: [
      { type: name,            /* Resource Object */
        id:123,
        attributes: {name: value,...},
        relationships: {
          name: {links: {}, data: [
            {type: name, id:234}, ... /* Resource Identifier Object */
          ],
      }, ...
    ],
    included: [
      { type: name,            /* Resource Object */
        id:123,
        attributes: {name: value,...},
        relationships: {},
        links: {self:url, ...}
      }, ...
    ],
    errors: [
      { id: uniqueIdentifier,        /* Error Object */
        links: {about: url},
        status: http_status_code,
        code: application_error_code,
        title: "Short human readable, no details",
        detail: "Human readable with details"
        source: {
          pointer: "/data/attributes/title",
          parameter: which URI param caused error},
        meta: { ... non-standard response details here ... }
      }, ...
    ],
    meta: { ... non-standard response details here ... }
    jsonapi: { ... server implemtation deatils ... }

Notes:

* A good example is on the [JSONAPI Home Page](http://jsonapi.org)
* **data** can be an array if multiple records requests, or a single
  object.
* Not all keys are required, but they'll show up when they should.
* **Resource Identifier Objects** contain no attributes, only "type" and
  "id's". You must request to "include=relationship" to have the full
  records returned in the "included" section
* **included** is an array of mixed types that should be uniquely
  referenced by both "type" and "id" keys.
* Attribute names are hyphenated instead of camel-cased or snake-cased.
  "full\_name" must be sent and received as "full-name". That should make
  your inner COBOL programmer happy!
* I've simplified the allowed variations to get our heads wrapped
  around it for now. The full specification is very readable.

## Building the API

Now we know how to speak and read JSONAPI, so the implementation details
can make sense as we implement our API. As it turns out, our app is the
next hottest blogging platform, so our API will use the objects and
relationships you already know! Let's get started with posts and
comments. I'll create them both at once for clarity, but I know you'll
build them properly on your own.

    rails g jsonapi:resource Api::V1::Post
    rails g jsonapi:controller Api::V1::Post
    rails g jsonapi:resource Api::V1::Comment
    rails g jsonapi:controller Api::V1::Comment

Wait, what's that "Api::V1" for? That's the namespace we discussed
earlier. Your JR Resource and Controller have to be in the same
namespace. Now we'll add them to our `config/routes.rb` file:

    namespace :api do
      namespace :v1 do
        jsonapi_resources :posts
        jsonapi_resources :comments
      end
    end

Our JR Resources inherit from `JSONAPI::Resource` and
`JSONAPI::ResourceController`, but I like to share application-specific
methods like we do with ApplicationController, ApplicationHelper, and
ApplicationRecord, so let's create our own class to inherit from, and
change the generated files to inherit from ours. We'll also stick the
application level classes in the versioned API namespace because they
may change by version.

```ruby
    # app/controllers/api/v1/api_resource_controller.rb
    class Api::V1::ApiResourceController < JSONAPI::ResourceController
    end

    # app/resources/api/v1/application_resource.rb
    class Api::V1::ApplicationResource < JSONAPI::Resource
      # An optional Meta object added to every request
      def meta(options)
        { copyright: "© #{Time.now.year} WAAS - WeblogAsAService, Inc." }
      end
    end

    # app/resources/api/v1/post_resource.rb
    class Api::V1::PostResource < Api::V1::ApplicationResource
    end

    # app/controllers/api/v1/posts_controller.rb
    class Api::V1::PostsController < Api::V1::ApiResourceController
    end
```

### Configure JSONAPI

I'll create a basic configuration inside the JR initializer file.

```ruby
    # config/initializers/jsonapi_resources.rb:
    JSONAPI.configure do |config|
      # built in paginators are :none, :offset, :paged
      config.default_paginator = :paged
      config.default_page_size = 50
      config.maximum_page_size = 1000

      # Do this if you use UUID's instead of Integers for id's
      config.resource_key_type = :uuid
    end
```

### Configuring our Resources

Your resource magically finds your model when you are using the same
name. Otherwise, there are a few configurations you can use to be more
explicit.  JR's DSL is straightforward.

* **attributes** - list of symbols as attributes to expose
* **has_many** - Sets up a one to many relationship
* **has_one** - Sets up a one to one relationship
* **filter** - defines an attribute can be used as a filter
* **filters** - lists attributes that can be used as a filter

Here's a simple version of our resources:

```ruby
    # app/resources/api/v1/post_resource.rb
    class Api::V1::PostResource < Api::V1::ApplicationResource
      attributes :title, :body, :status
      has_many   :comments
      filters    :id, :title
      filter     :status, default: "published,pending"
    end

    # app/resources/api/v1/comment_resource.rb
    class Api::V1::CommentResource < Api::V1::ApplicationResource
      attributes :created_at, :body, :author
      has_one    :post
      filters    :id, :author
    end
```

A full read of the
[JSONAPI Resources README](https://github.com/cerebris/jsonapi-resources)
will show you all the customization you can do.
You will have a lot of requirements as you proceed and can find most of
your answers there.

### Authentication

We'll need authentication on our API.  Authentication is a big subject,
but I'll just touch on the relevant parts for this use case.
There are several authorization techniques, but API's usually use an
"API Key" for access, usually a 32-character hexadecimal string,
probably from a randomly generated UUID, like
`SecureRandom.uuid.gsub("-","")`. We'll add an api\_key column of type
UUID to the users table and assign the key at create time. (Note: This
is not secure, it is the same as putting clear-text passwords in your
database, but I know you know better. Check out
[devise_token_auth](https://github.com/lynndylanhurley/devise_token_auth).)
Token-based access like this needs the HTTP Authorization header such as:

    Authorization: Token token="2253b04477254110b3ea30997b71a38a"

If your app is servicing a Javascript front-end app like Ember, React,
Angular, etc., you may also want to handle HTTP Basic Authentication as
a login method. It could return a session token to you to use until it
times out or logs out. Check out the best solution for your platform.

You can setup a `before_action` hook to check the header. Something like
this (hand-wavy code):

```ruby
    # app/controllers/api/v1/api_resource_controller.rb
    before_action :authorize!

    def authorize!
      hdr = request.headers["Authorization"]
      if hdr && hdr =~ /\AToken\s+(token="?)?(.+?)"?\s*\z/
        return true if valid_apikey?($2)
      end
      render(status: :unauthorized, json:{errors:[{
        status:401, code:"unauthorized", title:"Unauthorized"
      }]})
    end

    def valid_apikey?(key)
      @user = User.find_by(api_key:key)
      !!@user # Make boolean
    end
```

### Context

Every request carries some context, such as who is making the request.
We'll usually want to restrict records to those the current user
(identified by an Authentication header) owns. The
controller's context() method returns a Hash of key/value pairs that
could be used to limit the returned result to just the user's data.

At the start of the request, the controller identifies the user and
sets up the context hash as follows.

```ruby
    # api_resource_controller.rb
    def context
      # @user assigned in #authorize!()
      { api_user: @user }
    end
```

Now your Resource can scope the records returned. The records() class
method should return an Arel query object. Individual record finds are
chained off this object, so it will find the record by key only if the
user owns it. The context hash is passed to this method.

```ruby
    # app/resources/api/v1/post_resource.rb
    def self.records(options={})
      options[:context][:api_user].posts
    end
```

### Rate Limiting

If you need to limit the frequency requests to your service, you should
check out [rack-throttle](https://github.com/dryruby/rack-throttle).

### Webhook and Non-REST-ful Requests

Depending on your use case, standard REST requests can't always be sent.
I've worked with systems that can only send GET requests, so all payload
information and authentication must appear in the query string.

If your application needs to respond to these
[Webhooks](https://en.wikipedia.org/wiki/Webhook)
requests that are used by a limited client that doesn't understand
REST, you need to build a non-REST-ful interface.

For that case, I create a special endpoint and set up a controller that
maps the get request into a processing request. Here, I accept the
request and send it off into an ActiveJob so we can quickly return for
the client.

```ruby
    # config/routes: setup as "resources :webhook" under api/v1 namespace
    # /api/v1/webhook?apikey=foo&bar=baz&...
    # app/controllers/api/v1/webhook_controller.rb
    class Api::V1::WebhookController < Api::V1::ApiResourceController
      def index;  webhook; end
      def create; webhook; end
      def show;   webhook; end
      def update; webhook; end
      def delete; webhook; end

      private
      def webhook
        WebhookJob.perform_later(params.to_json)
        render(status: :accepted, plain:"OK")
      end
    end
```

### Try it out

Let's make REST Requests using your favorite REST posting tool.
(I use [Postman](https://www.getpostman.com/).)
Remember to set your Accept and Content-Type headers! I'll let you play
around with this as working through the details is that will really help
you learn JSONAPI. Start your app up locally and connect to localhost.

    POST http://localhost:3000/api/v1/posts
    Accept: application/vnd.api+json
    Content-Type: application/vnd.api+json
    Authorization: Token token="2253b04477254110b3ea30997b71a38a"

    {"data":{"type":"posts","attributes":{...}}}

Fetch some data:

    GET http://localhost:3000/api/v1/comments?filter[author]=pat
    Accept: application/vnd.api+json
    Authorization: Token token="2253b04477254110b3ea30997b71a38a"

Notes:

* Remember to hyphenate attribute names like "created-at".

### Using a JSONAPI Client

Check out the list of
[JSONAPI Client Libraries](http://jsonapi.org/implementations/#client-libraries),
as a starting point for your client. As I've shown, once you know how
JSONAPI works, the client isn't so hard, but a well-tested library will
help you integrate your API into your client.

## Summary

So that's about it. Now we have demystified JSONAPI, and understand how
to talk to it. Building API services that speak it is straightforward,
and so is consuming the results. JASONAPI is a fairly new protocol, but has
been methodically designed to handle most use cases. JR was developed
along side of it, so shows the best of Ruby and Rail's strengths and a
great data interchange format. Good luck!

