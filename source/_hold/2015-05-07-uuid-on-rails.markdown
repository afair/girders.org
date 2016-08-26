---
layout: post
title: "UUID on Rails"
date: 2015-05-07 22:01
comments: true
categories:
---
# UUID on Rails (with PostgreSQL)

By convention, Rails uses incrementing integers as "id" columns on its tables and models. It works for a lot of things, but sometimes we need something more, like the "Universally Unique IDentifier" or UUID.

## What's an UUID?

## Why would you need a UUID primary key?

* Large, sharded datasets
* Obsfucated ID values
* Hidden resources
* Multi-tenant Applications

When would an UUID be overkill?

* Apps with a lot of public URL's

## How do you setup a UUID Relation?

Migrations

Query

## Types of UUID's

## Short UUID's

* OMG, too long
* Nested URL's
* Friendly URL's (my-post-title-uuidSlug)

## Techniques for Sharded Databases
