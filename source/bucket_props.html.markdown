---
title: Bucket Properties
---
Riak has bucket properties, which allow individual buckets to take on different
behavior as needed. For example, the "posts" bucket may need to be searchable
with [Riak Search 2.0][4], or the "indexcache" bucket may not need a high quorum
or n-value.

[4]: http://docs.basho.com/riak/latest/dev/using/search/

**Generally, you do not want to use bucket properties in production with Riak
2.** Bucket properties aren't as efficient as assigning properties to bucket
types, and don't have the same permission restrictions as bucket type
properties.

## tl;dr

```ruby
bucket = client.bucket 'pages'
props = Riak::BucketProperties.new bucket
props['r'] #=> 3
props['r'] = 1
props.store
```

## The BucketProperties Class

New in the 2.2 version of the Ruby client is the `Riak::BucketProperties` class.
This class provides a `Hash`-like interface to bucket properties with
predictable semantics for when it reads and writes to Riak.

The object is intialized with a `Riak::Bucket` (or subclass, such as
`Riak::BucketTyped::Bucket`). The `Riak::BucketProperties` object does not
access Riak during initialization.

```ruby
bucket = client.bucket 'pages'
props = Riak::BucketProperties.new bucket

other_bucket = client.bucket_type('low_redundancy').bucket('page_cache')
other_props = Riak::BucketProperties.new other_bucket
```

### Reading Properties

Accessing a property on the object will hit Riak once:

```ruby
props['r'] # accesses Riak on first properties load
props['precommit'] # if data are loaded, does not access Riak
```

The `reload` method invalidates the cache and will hit Riak on the next
property read.

```ruby
props.reload
```

### Updating Properties

Updating bucket properties happens in two steps: set the desired values in the
`BucketProperties` instance, and `store` it into Riak:

```ruby
props['n_val'] = 1 # stage the value
props.store # write the value, invalidate cache
props['n_val'] # reads the properties from Riak
```

## Special Kinds of Properties

### Quorum Values: Integers and Strings

Some quorum values aren't integers, but a String representing a particular
kind of behavior.

Semantics of these values and how replication works can be found in the
[Replication Properties][1] page of the Riak documentation. Implementation of
these aliases is in the [`BucketPropertiesOperator`][2] class inside the
`BeefcakeProtobuffsBackend`, and the enumeration of these property names is in
the [`ProtobuffsBackend`][3] superclass.

[1]: http://docs.basho.com/riak/latest/dev/advanced/replication-properties/
[2]: https://github.com/basho/riak-ruby-client/blob/e6597f3d14757a6787494946d5c9a7cee32bfd5e/lib/riak/client/beefcake/bucket_properties_operator.rb#L60
[3]: https://github.com/basho/riak-ruby-client/blob/e6597f3d14757a6787494946d5c9a7cee32bfd5e/lib/riak/client/protobuffs_backend.rb#L19

### Hooks and Modfuns

Some bucket properties take a module/function pair, called a "modfun." These are
expressed as a `Hash` with `'mod'` and `'fun'` keys.

```ruby
props['chash_keyfun'] #=> {'mod' => 'riak_core_util', 'fun' => 'chash_std_keyfun'}
props['chash_keyfun'] = {'mod' => 'my_module', 'fun' => 'elite_custom_keyfun'}
```

Other bucket properties are an array of hooks, and a hook can be either a
function name or a modfun.

```ruby
props['precommit'] #=> [{'mod'=>'validate_json', 'fun'=>'validate'}]
props['precommit'] = [{'mod'=>'my_module', 'fun'=>'vowel_check'}]
props['postcommit'] #=> ['some_name', {'mod'=>'stats', 'fun'=>'update_stats'}]
props['postcommit'] << 'other_name'
```

The hook properties *can* be assigned as a modfun hash, but this leads to
inconsistent behavior locally:

```ruby
# Array of Hashes
props['precommit'] #=> [{'mod'=>'validate_json', 'fun'=>'validate'}]

# Assign a singular Hash
props['precommit'] = {'mod'=>'my_module', 'fun'=>'vowel_check'}

# Singular Hash
props['precommit'] #=> {'mod'=>'my_module', 'fun'=>'vowel_check'}

props.store

# Array of Hashes
props['precommit'] #=> [{'mod'=>'my_module', 'fun'=>'vowel_check'}]
```
