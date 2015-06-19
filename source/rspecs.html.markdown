---
title: Testing
---
We aim to have a comprehensive and fast set of tests, implemented using a modern,
well-supported version of RSpec. These tests include both unit specs for
individual classes, and integration specs that ensure the client works properly
with an actual Riak instance.

## tl;dr

1. Figure out what a feature should do.
2. Write integration specs in `spec/integration/`.
3. Observe their failure, commit them.
4. Figure out what implementation will be necessary.
5. Write implementation specs in `spec/riak/`.
6. Observe their failure commit them.
7. Develop feature.

## Project RSpec Standards

These standards are in place to ensure that specs are easy and predictable to
run, develop, and maintain. In general, we strive to match [Better Specs][1]
standards. In particular:

[1]: http://betterspecs.org

* Specs MUST NOT raise RSpec deprecation notices
* Specs MUST use `expect(something).to` style
* Specs MUST NOT use `something.should`
* Specs MUST NOT be order sensitive
* Integration specs MUST NOT use predictable names
* Specs SHOULD use `subject` and `let` to setting instance variables in
  `before` blocks
* Specs SHOULD use active voice, and SHOULD NOT use "should" in their name
* Specs MAY use `it{ is_expected.to }` style when appropriate

## Configuring for Running Tests

The [Riak Ruby Vagrant][2] virtual machine's Riak configuration is normally
used to test this client in development. Once it's up and running, configure
the Ruby `test_client.yml` on the host machine to connect to `pb_port: 17017`
and test away.

[2]: https://github.com/basho-labs/riak-ruby-vagrant

Configuring the Riak node the tests connect to is done via the
`spec/support/test_client.yml` file, which is loaded into a Ruby hash with
symbolized keys, and passed to `Riak::Client.new`.

```yml
# test_client.yml
pb_port: 10017
# UNCOMMENT AUTHENTICATION SECTION WHEN RIAK HAS SECURITY ENABLED
# authentication:
#   user: user
#   password: password
#   ca_file: spec/support/certs/ca.crt
```

### Spec dependencies

Specs depend on the following Riak configurations:

* The **LevelDB backend** is necessary for testing secondary indexes.
* **allow_mult** is required for many features: conflict resolution, and legacy
  counters among them.
* **Riak Search 2.0** ("Yokozuna") must be configured for testing full-text
  search.

The following bucket types are used during testing:

```shell
riak-admin bucket-type create counters '{"props":{"datatype":"counter", "allow_mult":true}}'
riak-admin bucket-type create other_counters '{"props":{"datatype":"counter", "allow_mult":true}}'
riak-admin bucket-type create maps '{"props":{"datatype":"map", "allow_mult":true}}'
riak-admin bucket-type create sets '{"props":{"datatype":"set", "allow_mult":true}}'
riak-admin bucket-type create yokozuna '{"props":{}}'

riak-admin bucket-type activate other_counters
riak-admin bucket-type activate counters
riak-admin bucket-type activate maps
riak-admin bucket-type activate sets
riak-admin bucket-type activate yokozuna
```

Client tests run both with and without security enabled, as we have to test
several positive and negative paths. The tests broadly depend on these users
and roles:

```shell
riak-admin security add-user user password=password
riak-admin security add-user certuser

riak-admin security add-source user 0.0.0.0/0 password
riak-admin security add-source certuser 0.0.0.0/0 certificate

riak-admin security grant riak_kv.get,riak_kv.put,riak_kv.delete,\
riak_kv.index,riak_kv.list_keys,riak_kv.list_buckets,\
riak_core.get_bucket,riak_core.set_bucket,\
riak_core.get_bucket_type,riak_core.set_bucket_type,\
search.admin,search.query,riak_kv.mapreduce on any to user
```
