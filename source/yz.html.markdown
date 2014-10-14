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

``` ruby
require 'riak'
client = Riak::Client.new
bucket = client.bucket 'pizzas'

# Create an index
client.create_search_index 'pizzas'
# Add the new index to a typed bucket. Setting the index on the bucket
# may fail until the index creation has propagated.
client.set_bucket_props bucket, {search_index: 'pizzas'}, 'yokozuna'

# Store records
meat = bucket.new 'meat'
meat.data = {toppings_ss: %w{pepperoni ham sausage}}
meat.store type: 'yokozuna'

hawaiian = bucket.new 'hawaiian'
hawaiian.data = {toppings_ss: %w{ham pineapple}}
hawaiian.store type: 'yokozuna'

# Search the pizzas index for hashes that have a "ham" entry in the
# toppings_ss array
result = client.search('pizzas', 'toppings_ss:ham') # Returns a results hash
result['num_found'] # total number of results
result['docs']      # the list of indexed documents
```

## Queries and Results

The Ruby client allows searching on an index level:
```ruby
results = client.search 'index_name', 'search query'
```

You can use normal [Lucene query syntax][1] for searching:

```ruby
results = client.search("famous", "name_s:Lion*")
results = client.search("famous", "age_i:[30 TO *]")
results = client.search("famous", "leader_b:true AND age_i:[30 TO *]")
```

The search method takes several optional parameters too:

```ruby
results = client.search('famous', "Olive", {sort: "age_i asc", rows: 1, df: 'dog_ss'})
```

The results object returned from the search has useful information:

```ruby
results['numFound'] #=> number of results found
results['docs'] #=> array of results

doc = results['docs'].first
doc['_yz_rb'] #=> bucket of document
doc['_yz_rk'] #=> key of document
```

[1]: https://lucene.apache.org/core/3_6_0/queryparsersyntax.html

## Indexes

Indexes are what actually connects search terms to documents. They can be created,
attached to buckets, and inspected from the Ruby client:

```ruby
# Creating an index requires the name, and can specify a schema, and an
# n-value for index replication too.
client.create_search_index 'index_name'
client.create_search_index 'index_name', 'schema_name', n_value

idx = client.get_search_index 'index_name'
# idx is an index object, with name, schema, and n_val accessors

client.get_search_index 'not_an_index' # raises Riak::ProtobuffsFailedRequest

# Attach the index_name to writes to bucket with the yokozuna bucket type.
client.set_bucket_props bucket, {search_index: 'index_name'}, 'yokozuna'
```

## Schemas

Schemas explain to Solr how fields should be indexed. They can be created and
read with the Ruby client:

```ruby
schema_content = File.read 'schema.xml'
client.create_search_schema 'schema_for_cool_cats', schema_content

schema_response = client.get_search_schema 'schema_for_cool_cats'
schema_response.name #=> "schema_for_cool_cats"
schema_response.content #=> "<?xml version..."
```
