---
title: Bucket Properties
---
Riak has bucket properties, which allow individual buckets to take on different
behavior as needed. For example, the "posts" bucket may need to be searchable
with [Riak Search 2.0][1], or the "indexcache" bucket may not need a high quorum
or n-value.

**Generally, you do not want to use bucket properties in production with Riak
2.** Bucket properties aren't as efficient as assigning properties to bucket
types, and don't have the same permission restrictions as bucket type
properties.

# tl;dr

```ruby
bucket = client.bucket 'pages'
props = Riak::BucketProperties.new bucket
props['r'] #=> 3
props['r'] = 1
props.store
```

# The BucketProperties Class

New in the 2.2 version of the Ruby client is the `Riak::BucketProperties` class.
This class provides a `Hash`-like interface to bucket properties with
predictable semantics for when it reads and writes to Riak.
