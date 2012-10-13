---
layout: post
title: Scaling PostgreSQL with Pgpool and PgBouncer
date: 2012-09-29 11:33
comments: true
categories: database
---

When you use PostgreSQL in production, you need to have reliability and
scalability. PostgreSQL is already a robust database server, fast,
reliable, and ready to rock.

I wrote this as a response to a lack of high-level documentation that I
needed to make decisions around deploying PostgreSQL and PgPool. It is
intended as a high-level guide, and the implementation configurations
are easy to find and set once you understand how it all works.

## Replication

There are a lot of replication solutions for PostgreSQL. In fact, until
release 9.0, PostgreSQL did not offer a built-in, official version. The
reason? PostgreSQL core team member Bruce Momjian spoke at the
Philadelphia Linus User's Group a couple years back and explained that
replication is not a "one size fits all" approach. There are many uses
of replication, from salesmen out in the field wielding laptops, to
application-specific requirements to a "Hot Standby" failover server.

PostgreSQL 9.0 came out with a Streaming Replication (SR) model. This
pushes out changes from the WAL to multiple slave PostgreSQL servers.
They apply that stream to their data, keeping it an exact copy of the
data, and staying in a "Hot Standby" mode, ready at a moment's notice to
be promoted to a master, should it fail. As a bonus, it can also serve
read requests from its database because of its relave low-latency, and
thus can offer load balancing.

The WAL, or Write Ahead Log, is the feature of PostgreSQL that allows it
to recover data, usually up to the point where the server stopped (from
hardware, software, or human error). As you make changes to your data,
PostgreSQL aggressively writes those changes to the WAL. This is not a
human-readable log of what happened, it is an internal data log allowing
PostgreSQL to replay the changes since the last Checkpoint.

A Checkpoint is a time limit where dirty buffers (containing changed
data pages) are flushed to disk. This flushing it done periodically for
performance, and to not overload the I/O devices, thus keeping the data
in sync between the disk and RAM versions.

## PostgreSQL Clusters

You do not just deloy a PostgreSQL server in a fault-intolerant setting.
You have to deploy a Cluster.

A PostgreSQL Cluster consists of a master PostgreSQL server, one or
more replication slaves, and some middleware like Pgpool, to take full
advantage of the cluster. You can use any form of replication that
supports a failover and load balancing features. The built-in SR does
this perfectly.

When you deploy your cluster, you should deploy as many slaves as can
handle the load should one server go off-line, a "n+1" scenario. When
you lose a slave, you need enough capacity to handle the usual load with
the remaining servers.

Under SR, the master database feeds your slave database(s) a live stream of
changes from the Write Ahead Log (WAL). The slaves apply this data and
stay "up to date" within a reasonable latency.

All you need is a load balancing middleware to send some of the read
queries to the slave database, such as Pgpool-II.

## PgPool-II

Pgpool is a middleware database utility that can perform several
functions, including:

  * Connection Pooling
  * Pgpool Replication
  * Load Balancing
  * Failover Handling
  * Parallel Query

By the term middleware, we say it sits between the PostgreSQL client and
server, speaking the PostreSQL server API to the clients, and
speaks the client API to the actual server, thus adding a level of
intelligence in the middle of the call chain.

A PgPool server associates with a PostgreSQL Cluster. It maps to a
PostgreSQL server (host+port), and the host+ports of its slaves or
clones. It can access any database on the associated PostgreSQL server
or Cluster. If this doesn't fit your use case, consider deplying a
PgBouncer middleware that talks to the various PgPool servers and their
associated PG servers.

### Connection Pooling

For connection pooling, Pgpool is configured to point to a specific
PostgreSQL host (and port). 

Connections are unique by database name and user. A Pgpool server
(hostname + port) can connect only to one PostgreSQL server, but can
"pool" connections to all databases within that cluster.

Strictly speaking, this is really coonnection caching, which will reuse
a previous connection or open a new one. Older, unused connections are
closed to use the resources for a newer connection. Unused connections
timeout after a given time, and are closed to conserve resources.

Pooling usually indicates a set of connections to a database, reused by
the application or client. PgPool does not commit to a per-database
set of connection, but caches requested access. If there is only one
hosted database on a host, and an application uses a single user to
connect to it, then it may appear as such a pool.
  
Pgpool intercepts all connection requests for that server and opens a
connection to the backend server with that database name and user
(Dbname + User). After the client closes the connection, Pgpool keeps it
open, waiting for another client to connect. 

### PgPool Replication

PgPool Replication sends all write requests to all servers in the
cluster. This is an alternative to Streaming Replication, and can be
used where SR is not available. However, it has a higher overhead, and
large write transactions will reduce performance.

Using PgPool Replication, all servers in the cluster run in normal mode,
and there is no need for a failover event should one server fail. The
other servers will pick up the load.

Streaming Replication is still recommended for high-volume applications.

### Load Balancing

PgPool load balancing splits read requests between all servers in the
replicated cluster.  Some replcation schemes do not make the slave
available for reads, so are not candidates for this feature.

To setup, you define your master database (named
backend_host0) and and slaves (backend_host1..n), then enable
load balancing. You must also list any functions you use that will back
data changes, to pgpool can identify write requests and read requests.

For streaming replication, postgresql will send all write requests to
the master server. (For simple replication, it would send them to all
servers.)

Read requests are balanced between the master and the slave servers. If
a slave server falls behind on its WAL stream updates, it will be
temporarily removed from the load balance set until it catches up. This
ensures data is as up-to-date as you need.

### Failover Handling

Pgpool can also be configured to detect a failure on the master
postgresql in the cluster and take an action that can promote a slave to
be the new master. After the point, it will forget the old master and
talk to the new master instead.

This can be tricky to have pgpool make this decision itself. Perhaps you
want to have a manual intervention depending on your operations. Once a
master is demoted, its data must be rebuilt from the new master to
become a master again.

### Parallel Query for Sharding and Partitioning

For large data sets that span servers, you can "shard" the tables,
splitting them up by a key column. Pgpool uses a configuration table
containing mapping the values of this column to a postgres server or
cluster.

When the client makes a data request, Pgpool inspects the query,
looks up the home location of the record, and forwards the request to
that server.

## PgBouncer

PgBouncer is an alternative connection pooling (again, caching)
middleware to Pgpool. It is smaller in footprint and only does pooling,
so it conserves resources.

In PgBouncer, you configure the pgbouncer as a postgresql connector. It
maps the dbnames you connect to locally into real databases that can
live on multiple hosts thoughout your system.

A database connection is configured as:

    app_db = host=pg1 port=nnnn dbname=app user=uuuu ...
    other_db = host=pg2 port=nnnn dbname=whatever user=uuuu ...

When you make a connection to "app_db" it will proxy and forward the
request to the real location of the database. After the client closes
the connection, it will keep it open for reuse from another client, or
until it times out. Pgbouncer can also maintain an actual pool of
connections for each database entry, limiting the amount of outbound
connections to a database.

PgBouncer is a great choice when you want to pool connections to
multiple postgresql servers. If you still need the load balancing,
replication, or failover features of Pgpool, you can use both
middlewares in series.

  * Appliation Client Connects to PgBouncer
  * PgBouncer forwards request to a PgPool for that cluster
  * PgPool forwards Request to the PostreSQL server (master or slave)
  * PostgreSQL responds to the request
