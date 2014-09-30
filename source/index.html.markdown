---
title: Riak Ruby Client
---

`riak-client` is a rich Ruby client/toolkit for Riak, Basho's
distributed database that contains a basic wrapper around typical
operations, including bucket manipulation, object CRUD, link-walking,
and map-reduce.

## tl;dr

Depend:

```ruby
# Gemfile
gem 'riak-ruby-client', '~> 2.0.0'
```

Install:

```shell
$ bundle
```

Code:

```ruby
#!/usr/bin/env ruby
require 'riak'

client = Riak::Client.new pb_port: 17017
bucket = client.bucket 'cats'

a = bucket.get_or_new 'alice'
a.data = 'meeeoooowwww'
a.content_type = 'text/plain'
a.store

z = bucket['zedo']
z.data #=> 'hissing sound'
```
