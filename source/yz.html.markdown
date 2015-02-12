---
title: Search
---
Riak 2 features two search systems. New in Riak 2 is "Riak Search 2.0," which was
developed under the codename "Yokozuna." It uses [Solr][1] for indexing and
querying, and `riak-core` for distributing and sharding indexes.

[1]: http://lucene.apache.org/solr/

This document covers using Riak Search 2.0 with the Ruby client. See the full
[Riak Search documentation][2] for more about working with search itself.

[2]: http://docs.basho.com/riak/latest/dev/using/search/

## tl;dr

This documentation assumes you have a `yokozuna` bucket type defined.

```ruby
require 'riak'
client = Riak::Client.new
bucket = client.bucket_type('yokozuna').bucket('pizzas')

# Create an index
index = Riak::Search::Index.new client, 'pizzas'
index.exists? #=> false
index.create!

# Add the new index to a typed bucket. Setting the index on the bucket
# may fail until the index creation has propagated.
props = Riak::BucketProperties.new bucket
props['search_index'] = index.name
props.store

# Store records
meat = bucket.new 'meat'
meat.data = {toppings_ss: %w{pepperoni ham sausage}}
meat.store

hawaiian = bucket.new 'hawaiian'
hawaiian.data = {toppings_ss: %w{ham pineapple}}
hawaiian.store

# Search the pizzas index for hashes that have a "ham" entry in the
# toppings_ss array
query = Riak::Search::Query.new client, index, 'toppings_ss:ham'
query.rows = 5
result = query.results
result.num_found           # total number of results
result.length              # total number returned, can be less than num_found
result.docs.first          # metadata about the search result
result.docs.first['score'] # result score
result.first               # the first found RObject
```

## Indexes

Indexes connect search terms to documents. They can be created,
attached to buckets, and inspected from the Ruby client:

```ruby
existing_index = Riak::Search::Index.new client, 'existing_index'

existing_index.exists? #=> true
existing_index.create! # raises Riak::SearchError::IndexExistsError

new_index = Riak::Search::Index.new client, 'a_cool_new_index'

new_index.exists? #=> false

# Creating an index can only be done once
new_index.create! #=> true
new_index.create! # raises Riak::Search::IndexExistsError

# Creating an index allows you to specify the schema and n-value for replication
fancy_index = Riak::Search::Index.new client, 'fancy_index_for_fancy_documents'
fancy_index.create! 'schema_name', n_value

# Indexes have accessors:
fancy_index.n_val #=> 3
fancy_index.schema #=> 'schema_name'
```


### Indexes and Buckets

Riak objects aren't indexed by default.  You can set a bucket's properties to
index objects on write.

```ruby
props = Riak::BucketProperties.new bucket
props['search_index'] = 'index_name'
props.store
```

## Queries and Results

The Ruby client allows searching on an index level:
```ruby
query = Riak::Search::Query.new client, index, 'search query'
results = query.results
```

You can use normal [Lucene query syntax][1] for searching:

```ruby
query = Riak::Search::Query.new(client, 'famous', "name_s:Lion*")
query = Riak::Search::Query.new(client, 'famous', "age_i:[30 TO *]")
query = Riak::Search::Query.new(client, 'famous', "leader_b:true AND age_i:[30 TO *]")
```

Queries have optional parameters too:

```ruby
query.sort = 'age_i asc'
query.rows = 1
query.df = 'dog_ss'
```

The results object returned from the search has useful information:

```ruby
results.num_found #=> number of results found
results.docs      #=> array of ResultDocument instances with result metadata

robject = results.first
```

[1]: https://lucene.apache.org/core/3_6_0/queryparsersyntax.html

## Schemas

Schemas explain to Solr how fields should be indexed. They can be created and
read with the Ruby client:

```ruby
schema_content = File.read 'schema.xml'
schema = Riak::Search::Schema.new client, 'schema_for_cool_cats'
schema.exists? #=> false
schema.content = schema_content
schema.create!

other_schema = Riak::Search::Schema.new client, 'some_other_schema'

other_schema.name #=> "some_other_schema"
other_schema.content #=> "<?xml version..."

other_schema.exists? #=> true
other_schema.create! # raises Riak::SearchError::SchemaExistsError
```

Just like indexes, schemas can only be created once per cluster.
