---
title: CRDTs
---
Convergent Replicated Data Types, or CRDTs, are data structures that remain
coherent and make sense even in eventually-consistent environments like Riak.
An understanding of the [Riak CRDT theory and implementation][1] will be useful
and should also be enjoyable.

[1]: http://docs.basho.com/riak/latest/theory/concepts/crdts/

## tl;dr

These examples assume you have bucket types named `counters`, `maps`, and `sets`.

```ruby
counter = Riak::Crdt::Counter.new counter_bucket, key
counter.value #=> 15
counter.increment
counter.value #=> 16
counter.increment 3
counter.value #=> 19
counter.decrement
counter.value #=> 18

map = Riak::Crdt::Map.new map_bucket, key
map.counters['potatoes'].value #=> 5
map.sets['potatoes'].include? 'yukon gold' #=> true
map.sets['cacti'].value #=> #<Set: {"saguaro", "prickly pear", "fishhook"}>
map.sets['cacti'].remove 'prickly pear'
map.registers['favorite butterfly'] = 'the mighty monarch'
map.flags['pet cat'] = true
map.maps['atlantis'].registers['location'] #=> 'kennedy space center'
map.counters.delete 'thermometers'

set = Riak::Crdt::Set.new set_bucket, key
set.members #=> #<Set: {"Edinburgh", "Leeds", "London"}>
set.add "Newcastle"
set.remove "London"
set.include? "Leeds" #=> true
```

## CRDTs and Bucket Types

CRDTs require appropriate bucket types to be configured. For more information,
check out the [Riak CRDT usage documentation][2].

[2]: http://docs.basho.com/riak/latest/dev/using/data-types/#Setting-Up-Buckets-to-Use-Riak-Data-Types

The Ruby client comes pre-configured with default bucket types for the three
top-level CRDTs: `counters`, `maps`, and  `sets`. These can be viewed and
changed in the `Riak::Crdt::DEFAULT_BUCKET_TYPES` hash:

```ruby
Riak::Crdt::DEFAULT_BUCKET_TYPES[:set] #=> "sets"

Riak::Crdt::DEFAULT_BUCKET_TYPES[:set] = "a_cooler_set"
```

Using a non-default bucket type is easy. The third argument for CRDT
constructors accepts a `String` that's a bucket type name, or in 2.2 and newer
clients, a `Riak::BucketType` instance. Additionally, if the first argument is
a `BucketTyped::Bucket`, it'll grab the type from that:

```ruby
other_counters_type = client.bucket_type 'other_counters'
typed_bucket = other_counters.bucket 'cool_counters'

untyped_bucket = client.bucket 'cool_counters'

# These three are equivalent:
c = Riak::Crdt::Counter.new untyped_bucket, 'shades', other_counters_type
c = Riak::Crdt::Counter.new untyped_bucket, 'shades', 'other_counters'
c = Riak::Crdt::Counter.new typed_bucket, 'shades'
```

## Creating and Loading CRDTs

CRDTs aren't strictly "created" per se. If multiple parties create a CRDT
with the same bucket and key at the same time, they will merge correctly. If
you attempt to load a CRDT that doesn't exist, you'll simply get it in its base
state: a counter will be zero, a set will be empty, and a map will not have any
contents.

Creating CRDTs is easy: pass the appropriate constructor a bucket and key, and
it'll use the default bucket type from the hash described above:

```ruby
counter = Riak::Crdt::Counter.new counter_bucket, key
map = Riak::Crdt::Map.new map_bucket, key
set = Riak::Crdt::Set.new set_bucket, key
```

You can create CRDT instances with a specific bucket type if you don't want the
default:

```ruby
counter = Riak::Crdt::Counter.new counter_bucket, key, 'counter_bucket_type'
map = Riak::Crdt::Map.new map_bucket, key, 'map_bucket_type'
set = Riak::Crdt::Set.new set_bucket, key, 'set_bucket_type'
```

If you want a Riak-assigned key, pass in `nil` for the key:

```ruby
counter = Riak::Crdt::Counter.new counter_bucket, nil
map = Riak::Crdt::Map.new map_bucket, nil
set = Riak::Crdt::Set.new set_bucket, nil

# write values in to actually make sure the CRDT exists
counter.increment
map.registers['furniture'] = 'cat apartment building'
set.add 'turnpike'

counter.key #=> "y1RejxFfDER/C8rxdmbjIiW356hj"
map.key #=> "t75x6BmnYh8aieiRsBNFfT1AEWpJ"
set.key #=> "hEBcIOc3cvTffQnYxJqMIQVMsFBG"
```

CRDT instances don't necessarily fetch their value on creation; they attempt to
load it on demand though:

```ruby
# doesn't hit Riak
counter = Riak::Crdt::Counter.new counter_bucket, key

counter.value # does hit Riak
counter.increment # does hit Riak
```

### Deleting CRDTs

Riak doesn't directly support deleting a CRDT object. Instead, delete it through
the KV interface.

```ruby
counter_robject = counter_bucket.get(key)
counter_robject.delete
```

Deleting it this way ensures that the delete operation includes the causal
context, which prevents non-deterministic results when the CRDT is modified
concurrent to its deletion.

## Immediate and Batched Changes

Altering CRDTs directly sends changes to Riak immediately, and refreshes the
local copy as part of the update:

```ruby
c1 = Riak::Crdt::Counter.new bucket, 'ctr'
c2 = Riak::Crdt::Counter.new bucket, 'ctr'

c1.value #=> 5
c2.value #=> 5

c1.increment # round-trips to Riak
c2.increment # round-trips to Riak

c1.value #=> 6
c2.value #=> 7

c1.reload # round-trips to Riak
c1.value #=> 7
```

When doing multiple changes to a CRDT in quick succession, it will be faster
to batch them up into a single write.

```ruby
map.batch do |m|
  m.counters['hits'].increment
  m.sets['followers'].add 'basho_elevator'
end
```

## Counters

Riak 2 supports counters in the same way as other CRDTs. Counters are basically
an integer you can increment or decrement.

**CAVEAT:** in error cases, there's no way to tell if a counter increment
has happened or not. If you don't retry a counter increment, it may or may not
have incremented. If you do retry a counter increment, it may be incremented
once or more than once.

Counters suport incrementing and decrementing:

```ruby
# note the `nil` key below: we're using a Riak assigned key
c = Riak::Crdt::Counter.new counter_bucket, nil

c.value #=> 0
c.increment # value is 1
c.increment # value is 2

c.increment 5 # value is 7

c.decrement # value is 6

c.decrement 4 # value is 2
```

## Sets

Riak 2 has sets of strings of bytes. In cases of conflict,

**PROTIP:** Ruby's standard library and the Riak client both have classes named
`Set`, and the Riak client uses the Ruby version copiously. Be careful to refer
to the Ruby version as `::Set` and the Riak client version as `Riak::Crdt::Set`.

```ruby
s = Riak::Crdt::Set.new set_bucket, nil

# Riak::Crdt::Set#members returns a ::Set instance
set.members #=> #<Set: {}>

# the #to_a method returns an Array
set.to_a #=> []

set.add 'manchego'
set.add 'gruyere'
set.add 'cheddar'

set.members #=> #<Set: {"manchego", "gruyere", "cheddar"}>

set.remove 'gruyere'
set.members #=> #<Set: {"manchego", "cheddar"}>
```

## Maps

Riak 2 Map CRDTs are the most complicated of the three top-level CRDTs. They
can contain any of five different inner CRDTs:

* *Counters:* integers that can be incremented or decremented, same as the
  top-level counters.
* *Flags:* boolean values that can be updated to `true` or `false`. A flag
  prefers to be `true` in cases where it could be either.
* *Maps:* a map can contain maps, and those maps can contain maps, and so
  on.
* *Registers:* a register is a string of bytes. In a conflict, the most-recent
  version of the register is picked, based on timestamps.
* *Sets:* just like the top-level set CRDT, sets inside maps are sets of strings
  of bytes.

Each inner CRDT is in a collection of its own, keyed by strings. Maps don't have
naming conflicts internally: the namespaces for each kind of inner CRDT is
separate. There's nothing stopping you from having both an inner counter named
`cats` and an inner set named `cats`. Nested maps don't conflict either, so
feel free to store maps in maps in maps.

### Creating and Updating Map Contents

Maps have five methods you'll be interacting with most of the time: `#counters`,
`#flags`, `#maps`, `#registers`, and `#sets`.

*Implementation detail:* these collections are instances of the
`Riak::Crdt::TypedCollection` class, which does some tricks to make the user
API work.

Flags and registers let you assign their values directly:

```ruby
m.flags['yes'] = true
m.flags['no'] = false

m.registers['singular'] = 'potato'
m.registers['cat'] = File.read 'cat.jpg'
```

Counters, maps, and sets have the same API as their top-level types:

```ruby
m.counters['emacs'].increment
m.counters['emacs'].value #=> 1

m.maps['racks'].sets['snacks'].add 'scooby snacks'

m.sets['garage'].add 'maybach'
```

### Deleting Map Contents

Map entries can be deleted from their collection:

```ruby
m.counters.delete 'emacs'
m.maps.delete 'racks'
m.sets.delete 'garage'
```

## Legacy Counters

Riak 1.4 also supported counters, but through the key-value API instead of the
CRDT API.

For more information about 1.4-style counters in Riak, see [the Basho documentation](http://docs.basho.com/riak/latest/dev/references/http/counters/).

Counter records are automatically persisted on increment or decrement. The
initial default value is 0.

```ruby
# Firstly, ensure that your bucket is allow_mult set to true
bucket = client.bucket "counters"
bucket.allow_mult = true

# You can create a counter by using the bucket's counter method
counter = bucket.counter "counter-key-here"
counter.increment #=> nil

counter.value #=> 1

# Let's increment one more time and then retrieve it from the database
counter.increment

# Retrieval is similar to creation
persisted_counter = Riak::Counter.new bucket, "counter-key-here"

persisted_counter.value #=> 2

# We can also increment by a specified number
persisted_counter.increment 20
persisted_counter.value #=> 22

# Decrement works much the same
persisted_counter.decrement
persisted_counter.value #=> 21

persisted_counter.decrement 6
persisted_counter.value #=> 15

# Incrementing by anything other than integer will raise an ArgumentError
persisted_counter.increment "nonsense"
# ArgumentError: Counters can only be incremented or decremented by integers.
```
