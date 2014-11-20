---
title: Bucket Types
---

Bucket Types configure and scope bucket behavior. This document aims to describe
and explain how to use them with the Ruby client. For insight into how they
work inside Riak, read [the bucket type documentation][1].

This document covers the API implemented in the 2.2 version of the client.
Previous versions had much more limited support for bucket types.

[1]: http://docs.basho.com/riak/latest/dev/advanced/bucket-types/

## tl;dr

```ruby
# get some types
type = client.bucket_type 'my_cool_type'
counter_type = client.bucket_type 'other_counters'

# get a bucket-typed bucket
bucket = type.bucket 'pages'

# instantiate objects in a bucket typed bucket
my_homepage = cool_pages.get_or_new 'index.html'
under_construction = cool_pages.new 'under_construction.gif'
background_music = cool_pages.get 'STAIRW~1.MID'

# get a BucketTyped::Bucket and a regular Bucket
counter_bucket = counter_type.bucket 'hit_counters'
untyped_bucket = client.bucket 'hit_counters'

# instantiate a CRDT; these three are equivalent
ctr = Riak::CRDT::Counter.new counter_bucket, 'homepage'
ctr = Riak::CRDT::Counter.new untyped_bucket, 'homepage', counter_type
ctr = Riak::CRDT::Counter.new untyped_bucket, 'homepage', 'other_counters'
```

## Bucket Type Objects

`Riak::BucketType` instances can be created from `Riak::Client` instances:

```ruby
type = client.bucket_type 'my_cool_type'
type.is_a? Riak::BucketType #=> true
```

A type has a `name`, knows if it is the default type, and can fetch its
properties:

```ruby
type.name #=> 'my_cool_type'
type.default? #=> false
type.properties #=> {:allow_mult => true, :n_val => 1}
```

## Bucket-typed Buckets

`Riak::BucketTyped::Bucket` is a subclass of `Riak::Bucket`, with an additional
field for what type it is.

```ruby
bucket = client.bucket 'homepage'
typed_bucket = type.bucket 'homepage'

bucket.type # raises NoMethodError
typed_bucket.type #=> Riak::BucketType instance
```

## Types and Key-Value Objects

Key-value objects in a typed bucket are created from said bucket:

```ruby
my_homepage = typed_bucket.get_or_new 'index.html'
under_construction = typed_bucket.new 'under_construction.gif'
background_music = typed_bucket.get 'STAIRW~1.MID'
animated_fire = typed_bucket['fire.gif']
```

## The Default Bucket Type

Versions of Riak prior to 2.0 didn't support bucket types. While adding bucket
types to the API, operations that don't explicitly specify a bucket type use
the default type. Some APIs, including map-reduce, are picky about bucket types
being non-default.

*You will probably not need to deal with the default bucket type in this way:*

```ruby
default_type = client.bucket_type Riak::BucketType::DEFAULT_NAME
default_type.default? #=> true
```

For picky APIs, `Bucket` and `BucketTyped::Bucket` instances know whether
they need to include the type:

```ruby
bucket = client.bucket 'coffees'
bucket.needs_type? #=> false

default_typed_bucket = default_type.bucket 'coffees'
default_typed_bucket.needs_type? #=> false

typed_bucket = my_cool_type.bucket 'coffees'
typed_bucket.needs_type? #=> true
```
