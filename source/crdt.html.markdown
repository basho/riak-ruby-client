---
title: CRDTs
---
Convergent Replicated Data Types, or CRDTs, are data structures that remain
coherent and make sense even in eventually-consistent environments like Riak.

# tl;dr

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

# CRDTs and Bucket Types

CRDTs require appropriate bucket types to be configured. For more information,
check out the [Riak CRDT documentation][1].

[1]: http://docs.basho.com/riak/latest/dev/using/data-types/#Setting-Up-Buckets-to-Use-Riak-Data-Types

The Ruby client comes pre-configured with default bucket types for the three
top-level CRDTs: `counters`, `maps`, and  `sets`. These can be viewed and
changed in the `Riak::Crdt::DEFAULT_BUCKET_TYPES` hash:

```ruby
Riak::Crdt::DEFAULT_BUCKET_TYPES[:set] #=> "sets"

Riak::Crdt::DEFAULT_BUCKET_TYPES[:set] = "a_cooler_set"
```

# Immediate and Batched Changes

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
