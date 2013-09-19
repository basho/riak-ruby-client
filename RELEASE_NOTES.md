# Riak Ruby Client Release Notes

## 1.4.2 Bugfix Release - TBD

Release 1.4.2 fixes a couple bugs.

Issues:

* Secondary index queries against non-2i-enabled buckets/backends now raise a
  useful exception.

Bugfixes:

* 2i Requests over PBC block forever when 0 results match in 1.4.x,
  reported by Sean "graphex" McKibben in
  https://github.com/basho/riak-ruby-client/pull/121 and
  https://github.com/basho/riak-ruby-client/pull/122
* RObject#links is an Array when loaded from PBC, reported by Dan Pisarski in
  https://github.com/basho/riak-ruby-client/pull/123
* Bucket listing doesn't work with HTTP backend,
  reported and fixed by Wagner Camaro in
  https://github.com/basho/riak-ruby-client/pull/124

## 1.4.1 Patch/Bugfix Release - 2013-09-06

Release 1.4.1 fixes a few minor bugs and issues.

Issues:

* Test for object existence using head request, reported and fixed by
  Elias "eliaslevy" Levy in https://github.com/basho/riak-ruby-client/pull/102

Bugfixes:

* License missing from gemspec, reported by Benjamin "bf4" Fleischer
  in https://github.com/basho/riak-ruby-client/pull/108
* Debugger required by Gemfile, reported by Basho Giddyup
  in https://github.com/basho/riak-ruby-client/pull/114
* Issue when reading Git-based version numbers, reported and fixed by
  jacepp in https://github.com/basho/riak-ruby-client/pull/120

## 1.4.0 Feature Release - 2013-08-16

Release 1.4.0 adds support for Riak 1.4 and fixes a few bugs.

Features for all Riak versions:

* Multi-get parallelizes fetching multiple objects from one or more
  buckets.
  
Features for Riak 1.4 and newer:

* Bucket properties are settable and resettable over Protocol Buffers.
* Distributed counters are implemented by the `Riak::Counter` class.
* The full set of improvements to Secondary Indexes
  are available, including pagination, streaming, and return_terms.
  These features are available through the existing `Bucket#get_index`
  interface as well as the new `Riak::SecondaryIndex` interface.
* The new streaming bucket list is available in the Ruby client.
* Setting timeout values for object CRUD, key listing, and bucket
  listing is now possible.

Bugfixes:

* Tests pass and don't stall in Ruby 2.0.
* Zero-length key and bucket names are forbidden in the client.
* Test server works with Riak 1.4.

## 1.2.0 Feature Release - 2013-05-15

Release 1.2.0 adds support for Riak 1.3 and fixes a number of bugs.

Features:

* The "clear bucket properties" feature has been added. This resets
  modified bucket properties to the defaults on Riak 1.3+ clusters.
* Anonymous "strfun" MapReduce functions written in Erlang can now be
  sent from the client, if they are enabled on the server-side.

Bugfixes:

* The WalkSpec class now properly includes the Translation module.
* The Protocol Buffers transport now extracts the bucket name before
  submitting secondary index queries.
* Search query results returned over PBC are assumed to be UTF-8
  encoded.
* The newer Excon API is now supported (>= 0.19.0).
* When enabling the search commit hook, the 'precommit' property will
  now be checked more safely.

## 1.1.1 Patch/Bugfix Release - 2013-01-10

Release 1.1.1 fixes a minor bug with Net::HTTP on Ruby 1.8.7 with
patch level less than 315, where an exception would cause closing the
socket before it was opened.

## 1.1.0 Feature Release - 2012-11-07

Release 1.1.0 includes full Riak 1.2 compatibility, and includes
improvements to the handling of siblings, the node generation
tools, and resolves a number of important bugs.

Features:

* Client features are enabled or disabled based on the detected Riak
  version.
* Riak 1.2 compatibility, including search and 2I over Protocol
  Buffers.
* Phaseless MapReduce (which was available in 1.1) is allowed, using
  feature detection to determine whether an exception is raised.
* Conditional store_object operations on Protocol Buffers use the
  message features available since Riak 1.0.
* The integration test-suite can be run without generating a test
  node, which lets us support riak_test.

Bugfixes:

* URL-escaping now allows some normally URI-safe characters to be
  escaped.
* JRuby should be more reliable when attaching to a generated node's
  console.
* The client backend pool has been extracted to the Innertube gem,
  which is now a dependency.
* Fix a documentation issue around key-filters.
* Fix RSpec formatter and deprecation errors.
* Object siblings are now a separate class (RContent) rather than
  being unclean copies of the parent RObject. If only one sibling
  exists, the original accessors (e.g. `content_type`, `data`) will
  behave as expected. When more than one sibling exists, they will
  raise `Riak::Conflict`. This should prevent unintentional storing of
  unresolved objects back into Riak as `multipart/mixed` values.
* `Riak::Client#ssl=` won't blow away existing `ssl_options` if set to
  `true`.
* Generated nodes will ensure that the source's
  `ssl_distribution.args_file` exists by invoking `riak chkconfig`.
* Copy fixes for the `$key` index on the memory/test backend from
  riak_kv.
* The shape of MapReduce results will no longer be changed by the
  Protocol Buffers backend, which manifested as kept phases without
  results being removed from the return value. Implementing this
  required all HTTP requests to use streaming, even if invoked without
  a block.

## 1.0.5 Packaging Fix Release - 2012-10-12

Release 1.0.5 fixes a bug with the RubyGems packaging that
inadvertently included the `pkg` directory, which might have included
old gem versions. No client functionality has changed with this
release.

## 1.0.4 Patch/Bugfix Release - 2012-07-06

Release 1.0.4 fixes some bugs and adds configurable timeouts to the
Excon HTTP backend.

**NOTE** This will likely be the last release in the 1.0.x series. The
planned changes for 1.1.x are:

* `Riak::Client::Pool` will be replaced by the `innertube` gem, which
  is its extraction.
* Riak 1.2 will be fully supported, including the new native 2I and
  Search features over PBC.
* A richer exception hierarchy so that applications can deal more
  intelligently with request failures.

Changes in 1.0.4:

* A function in the `app_helper` module that does not exist on Riak
  1.1 and earlier was copied into the KV test backend.
* Excon's configuration logic was made more idempotent.
* Added timeout support to the Excon HTTP backend. [Mat Brown] 
* Corrected an misnamed constant in Excon which would cause timeouts
  not to be recognized as network errors.
* The `Riak::TestServer` is now compatible with Riak 1.2.
* A documentation error around `RObject#data` in the README was
  fixed. [dn@wortbit.de]
* Fixed an ETS table leak in the testing backend.
* Deprecation warnings for later versions of MultiJson are now
  resolved.

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
