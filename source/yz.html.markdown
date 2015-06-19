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
props['search_index'] = index
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
query = index.query 'toppings_ss:ham'
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
index objects on write. The `BucketProperties` object accepts either a
`String` index name, or a `Riak::Search::Index` instance for the `search_index`
property.

```ruby
props = Riak::BucketProperties.new bucket
props['search_index'] = 'index_name' # String
props['search_index'] = index_object # Riak::Search::Index
props.store
```

## Queries and Results

Riak allows you to search a given index. You can do this with the Ruby client
by creating a `Riak::Search::Query` object for a given index.

```ruby
# Already materialized the index? Ask it for a query:
query = index.query 'search query'

# Initialize a query with a client, index, and the search terms:
query = Riak::Search::Query.new client, index, 'search query'

# You can initialize a query with the index name instead of a materialized
# index:
query = Riak::Search::Query.new client, 'index_name', 'search query'

# Perform the query
results = query.results
```

You can use normal [Lucene query syntax][3] for searching:

[3]: https://lucene.apache.org/core/3_6_0/queryparsersyntax.html

```ruby
query = Riak::Search::Query.new(client, 'famous', "name_s:Lion*")
query = Riak::Search::Query.new(client, 'famous', "age_i:[30 TO *]")
query = Riak::Search::Query.new(client, 'famous', "leader_b:true AND age_i:[30 TO *]")
```

Queries have optional parameters that can be assigned at initialization or
using regular attribute setters:

```ruby
# Index#query takes an options hash as a second argument
query = index.query 'name_s:Lion*', rows: 5, df: 'dog_ss'

# Query.new takes an options hash as the fourth argument
query = Riak::Search::Query.new(client,
                                index,
                                'age_i:[30 TO *]',
                                sort: 'age_i desc',
                                start: 15
                                )

# Options also have accessor methods defined
query.sort = 'age_i asc'
query.rows = 1
query.df = 'dog_ss'
```

### Result Collections and Result Documents

The `Query#result` method returns a `ResultCollection` object. This object has
useful information about the query response:

```ruby
results.num_found #=> number of results matching the query
results.length    #=> number of results returned from the query

results.max_score #=> highest score found by Solr
```

Perhaps more usefully, it provides access to an array of `ResultDocument`
instances, one for each document returned in the query.

```ruby
docs = results.docs       # Array<ResultDocument>
first_result = docs.first # ResultDocument

# addressing information
first_result.bucket_type # Riak::BucketType instance
first_result.bucket      # Riak::BucketTyped::Bucket instance
first_result.key         # String
```

### Materializing Results into Objects

You can materialize a Riak object from a `ResultDocument`, either a `RObject`
key-value object, or one of the many flavors of CRDT.

```ruby
# ask the result if it refers to a CRDT
first_result.crdt?
# ask the result what class it will use to materialize the object; returns
# the class Riak::RObject, or a Riak::Crdt::Base subclass
first_result.type_class

# materializes the object, no matter what the type_class
first_result.object

# materializes a CRDT, raises an error if it's not a CRDT
first_result.crdt

# materializes this kind of obejct, raises an error if it's not that
first_result.robject     # Riak::RObject
first_result.counter     # Riak::Crdt::Counter
first_result.map         # Riak::Crdt::Map
first_result.set         # Riak::Crdt::Set
```

Technically, any CRDT object can also be materialized as a regular key-value
object. This API doesn't allow you to do this to make corrupting a CRDT object
more difficult.

If you do actually need the RObject for a CRDT, perhaps to delete it, use the
fields on the `ResultDocument` to help out.

```ruby
map_result.map     #=> Riak::Crdt::Map instance
map_result.robject # raise Riak::SearchError::UnexpectedResultError

map_robject = map_result.bucket.get map_result.key #=> Riak::RObject instance
```

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
