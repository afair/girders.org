---
layout: post
title: Scaling PostgreSQL with Pgpool and PgBouncer
date: 2012-09-29 11:33
comments: true
categories: database
---

*Deploying PostgreSQL in a high-demand environment requires 
reliability and scalability. PostgreSQL's ecosystem offers the tools you
need to build out a robust database system. This guide offers a high-level
description of tools used to build a high-availability, scalable,
fault-tolerant service.*

These tools are explained

  * [PostgreSQL](http://www.postgresql.org/) Database with
    [Streaming Replication](http://wiki.postgresql.org/wiki/Streaming_Replication)
  * [Pgpool-II](http://www.pgpool.net/mediawiki/index.php/Main_Page) multipurpose connect proxy for PostgreSQL
  * [PgBouncer](http://wiki.postgresql.org/wiki/PgBouncer) connection pooler for PostgreSQL
  * [Repmgr](http://www.repmgr.org/) - Replication Manager for
    PostgreSQL Clusters

Pgpool, the hardest to grasp, can be configured to perform connection
pooling and management, simple replication, load balancing, and parallel
query processing.


## Replication

PostgreSQL has many 
[replication](http://wiki.postgresql.org/wiki/Replication,_Clustering,_and_Connection_Pooling#Replication)
solutions with different approaches. In fact, until
release 9.0, PostgreSQL did not offer a built-in, official version. The
reason? PostgreSQL core team member Bruce Momjian spoke at the
Philadelphia Linux User's Group a couple years back and explained that
replication is not a "one size fits all" approach. There are many uses
of replication, from salesmen out in the field wielding laptops, to
application-specific requirements to a "Hot Standby" failover server.

PostgreSQL 9.0 introduced the built-in Streaming Replication (SR). SR
transmits changes from the WAL to multiple slave PostgreSQL servers.
Eash slave applies that stream to their data, keeping it an exact copy of the
data, and staying in a "Hot Standby" mode, ready at a moment's notice to
be promoted to a master, should the master fail. 

As a bonus, slave servers can also serve read-only requests from its database because of 
its relative low-latency, and thus can be used in load balancing.

The WAL, or [Write Ahead Log](http://www.postgresql.org/docs/devel/static/wal-intro.html), 
is the feature of PostgreSQL that allows it
to recover data, usually up to the point where the server stopped (from
hardware, software, or human error). As you make changes to your data,
PostgreSQL aggressively writes those changes to the WAL. This is not a
human-readable log like a web server would produce. 
The WAL is an internal, binary log of all committed changes to the database. 

When a maximum time limit has passed, or the buffer limit is reached,
PostgreSQL issues a *Checkpoint*. During the checkpoint, dirty buffers (containing changed
data pages) are flushed to disk to ensure against data loss, without
overloading I/O devices with constant writes.

This design allows recovery, should a failure (power, server, human error) occur. When 
PostgreSQL restarts, it replays the changes from the WAL since the last Checkpoint,
to bring the database back to the state of the last completed commit.

Under SR, the master database feeds your slave database(s) a live stream of
changes from the Write Ahead Log (WAL). The slaves apply this data and
stay "up to date" within a reasonable latency.

## PostgreSQL Clusters

A fault-tolerant system does not just deploy a single PostgreSQL server,
rather an PostgresSQL cluster is deployed.

A PostgreSQL Cluster consists of a master PostgreSQL server, one or
more replication slaves, and some middleware like Pgpool, to take full
advantage of the cluster. You can use any form of replication that
supports a failover and load balancing features. The built-in SR does
this perfectly.

When you deploy your cluster, should provision as many slaves as can
handle the load should a server go off-line, a "n+1" scenario. When
you lose a server, you need enough capacity to handle the load with
the remaining servers.

A single server is identified as the master, and the others are the
slaves. The master sends the WAL to each slave over the network. The
slaves apply the WAL feed to stay current, and in a "hot standby" state,
should the master fail. The slaves can't perform any updates of the own,
but can serve read-only queries to its clients.

To utilize the cluster, you need load balancing middleware such as
Pgpool to perform load balancing and failover.

## PgPool-II

Pgpool is a middleware database utility that can perform several
functions, including:

  * Connection Pooling
  * Pgpool Replication
  * Load Balancing
  * Failover Handling
  * Parallel Query

[Middleware](http://en.wikipedia.org/wiki/Middleware)
is software siting between the PostgreSQL client and
server, speaking the PostreSQL server API to the clients, and
speaks the client API to the actual server, thus adding a level of
intelligence in the middle of the call chain.

### PgPool with PostgreSQL Clusters

For use in a PostgreSQL Cluster, a PgPool server sits between the clients and
the master and slave servers. 

Clients connect to Pgpool instead of the database server and send 
database requests through Pgpool to the servers in the cluster. 
Configure with "Connection Pooling."

Pgpool sends all data mutation requests (update, create, delete, etc.) through
to the master server, and sends read requests (select) to any available
server, master or slave. Configure with "load balancing."

When Pgpool detects the master server has failed, it can issue a command
to promote a slave to be the next master. (Regmgr has better features for
managing this.) Configure with "failover."

### Connection Pooling

For connection pooling, Pgpool is configured to point to a specific
PostgreSQL host (and port). 

Connections are unique by database name and user. A Pgpool server
(hostname + port) can connect only to one PostgreSQL server, but can
"pool" connections to all databases within that cluster.

Strictly speaking, this is really connection caching, and will reuse
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
replicated cluster.  Some replication schemes do not make the slave
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
so it conserves resources and can be more efficient. 
It can cache connections to different databases, servers, or clusters (with Pgpool). 

In PgBouncer, you configure the pgbouncer as a postgresql connector. It
maps the dbnames you connect to locally into real databases that can
live on multiple hosts thoughout your system.

A database connection is configured as:

    app_db = host=pg1 port=nnnn dbname=app user=uuuu ...
    other_db = host=pg2 port=nnnn dbname=whatever user=uuuu ...

When a client connects to "app_db" it will proxy and forward the
request to the real location of the database. After the client closes
the connection, it will keep it open for reuse from another client, or
until it times out. Pgbouncer can also maintain an actual pool of
connections for each database entry, limiting the amount of outbound
connections to a database.

PgBouncer is a great choice when you want to pool connections to
multiple postgresql servers. If you still need the load balancing,
replication, or failover features of Pgpool, you can use both
middlewares in series.

  * Application Client Connects to PgBouncer
  * PgBouncer forwards request to a PgPool for that cluster
  * PgPool forwards Request to the PostreSQL server (master or slave)
  * PostgreSQL responds to the request

## Repmgr

Repmgr sets up your cluster replication and provides a daemon that monitors the nodes 
in your cluster for failure. 

First, you create replicated nodes from your original master. It copies
the underlying files from that server to another, which is run as a
slave. You designate the master and standby (or slave) nodes.

On failure, it can promote a slave to be the next master, takes the old
master out of the cluster until it can be repaired, and tells the other
slaves to follow the newly promoted master node.

You can re-provision a new (or old master) node to and introduce it to
the cluster.
