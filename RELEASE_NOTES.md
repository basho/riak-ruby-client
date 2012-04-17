# Riak Ruby Client Release Notes

## 1.0.3 Patch/Bugfix Release - 2012-04-17

Release 1.0.3 fixes some bugs and adds support for secondary indexes
when using `Riak::TestServer`.

* Added tests for secondary index features to the unified backend
  examples.
* Added secondary index support to `riak_kv_test_backend`. Full
  support for this feature will be available via
  `riak_kv_memory_backend` in the next major Riak release. See
  [riak_kv #314](https://github.com/basho/riak_kv/pull/314).
* The console log (`lager_console_backend`) is now enabled on
  generated nodes.
* `Riak::Node::Console` no longer overrides the `SIGWINCH` signal
  handler.
* [Excon](http://rubygems.org/gems/excon) versions >= 0.7.0 are now
  supported.
* IO-style objects will now be emitted properly when using the
  `NetHTTPBackend`. [#1](https://github.com/basho/riak-ruby-client/issues/1)
* The Riak version filter for integration specs is now more correct.
* `Riak::RObject#url` has been removed because its accuracy cannot be
  maintained when connected to multiple Riak nodes or to Riak via
  PBC. [#3](https://github.com/basho/riak-ruby-client/issues/3)
* Index entries on `Riak::RObject` can be mass-overwritten using
  `Riak::RObject#indexes=` while maintaining the proper internal
  semantics. [#17](https://github.com/basho/riak-ruby-client/issues/17)
* Nodes should now generate properly when the `riak` script is a
  symlink (e.g. Homebrew). [#26](https://github.com/basho/riak-ruby-client/issues/26)

## 1.0.2 Repackaging - 2012-04-02

Release 1.0.2 relaxes the multi_json dependency so that the client
will function with Rails 3.2. Version 1.0.1 was yanked.

## 1.0.1 Patch/Bugfix Release - 2012-04-02

Release 1.0.1 is a minor bugfix/patch release. Included in this
release are:

* I18n messages now include the French locale. [Eric Cestari]
* SSL configuration should work again. [Adam Hunter]
* The version comparison when checking Excon compatibility should now
  handle large version numbers correctly. [Srdjan Pejic]
* There is now a spec to verify that the `riak_kv` `add_paths` setting
  is not clobbered by the `Riak::TestServer` when adding the location
  of the test backend code.

## 1.0.0 Feature Release - 2012-02-03

Release 1.0.0 is a major feature release and is the first where
`riak-client`, `ripple`, and `riak-sessions` will be released
independently (see below). Because there too many individual changes
to recount, this entry will cover the major features and bugfixes
present in the release.

### Riak 1.0/1.1 Compatibility

`riak-client` is fully compatible with Riak 1.0.x and
(yet-to-be-released) 1.1.x, including supporting secondary indexes,
integrated search, and cluster membership commands.

### Multi-node Connections and Retries

`Riak::Client` can now connect to multiple Riak nodes at once. This
greatly improves throughput and allows the client to recover from
intermittent connection errors while continuing normal operation. To
enable this, all uses of the Pump/Fiber logic were removed in favor of
connection pools from which any new request can draw an existing or
create a new connection. Which node is selected for any new connection
is based on a quickly-decaying EWMA of its success rate on recent
requests. A huge thanks to [Kyle Kingsbury](https://github.com/aphyr)
who did most of the work on this!

### Improved TestServer and Node Generation

The `Riak::TestServer` class has been generalized such that you can
generate regular nodes and even clusters that store data on disk. This
is especially useful if you want separate nodes or clusters for each
project that uses Riak, and to keep them separate from your base
install. `TestServer` also now launches the node in a separate process
(not a child process) so you can keep it running between test
suites. Clearing the in-memory data is performed by connecting to the
console via the exposed Unix pipes, rather than over stdio.

### Conflict Resolution

An important part of dealing with eventual consistency is the ability
to handle when conflicts (also called siblings) are created. Now you
can resolve them automatically by registering blocks (callbacks) using
`Riak::RObject.on_conflict`. The block will be called when fetching a
key in conflict and receives a `RObject` that has siblings. To resolve
the conflict, it simply returns the resolved object, or nil if it
didn't handle the conflict. A huge thanks to
[Myron Marston](https://github.com/myronmarston) who implemented this!

### Serializers

Before, serialization of Ruby objects into Riak was constrained to
three formats: JSON, YAML and Marshal. Now you can define your own
serializers so that you can store data in BSON, MsgPack, NetStrings,
or whatever format you like. Use `Riak::Serializers[content_type] =
serializer` to assign a serializer for the selected media type. The
serializer must respond to `#dump` and `#load`. (More handiwork of Myron
Marston, thanks!)

### Stamps

If you don't like the keys that Riak hands out when you store an
`RObject` without a key, and you want something naturally ordered, you
can now generate them client-side using `Riak::Stamp`, which will
generate 64-bit integers in a fashion similar to Twitter's Snowflake,
but uses `Riak::Client#client_id` as the machine identifier.

### Repository/Feature split

In an effort to decouple development of the individual projects and
reduce top-level dependencies, the `ripple` repository was split into
new repositories containing its corresponding sub-projects.
Additionally, the `Riak::CacheStore` has become its own project/gem.
The new gem and repository locations are below:

* [`riak-client`](http://rubygems.org/gems/riak-client) &mdash;
  [basho/riak-ruby-client](https://github.com/basho/riak-ruby-client)
* [`ripple`](http://rubygems.org/gems/ripple) &mdash;
  [seancribbs/ripple](https://github.com/seancribbs/ripple)
* [`riak-sessions`](http://rubygems.org/gems/riak-sessions) &mdash;
  [seancribbs/riak-sessions](https://github.com/seancribbs/riak-sessions)
* [`riak-cache`](http://rubygems.org/gems/riak-cache) &mdash;
  [seancribbs/riak-cache](https://github.com/seancribbs/riak-cache)

### Significant Known Issues

Attempting to use the Protocol Buffers transport with a 0.14.x cluster
may cause the connection to dump because of incompatibilities in
certain protocol messages. This will be addressed in a future
patch/bugfix release.

The new node generation and test server intermittently fails on JRuby,
specifically from deadlocks related to blocking opens for the console
FIFOs. The JRuby team has helped on this issue, but there may not be a
clear resolution path until JRuby 1.7 or later.

Other known issues may be found on the
[Github issue tracker](https://github.com/basho/riak-ruby-client/issues?milestone=1).
