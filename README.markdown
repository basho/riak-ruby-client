# Riak Ruby Client (riak-client) [![Build Status](https://secure.travis-ci.org/basho/riak-ruby-client.png)](http://travis-ci.org/basho/riak-ruby-client)

`riak-client` is a rich Ruby client/toolkit for Riak, Basho's
distributed database that contains a basic wrapper around typical
operations, including bucket manipulation, object CRUD, link-walking,
and map-reduce.

## Dependencies

`riak-client` requires i18n, builder, beefcake, and multi_json. The
cache store implementation requires ActiveSupport 3 or later.

Development dependencies are handled with bundler. Install bundler
(`gem install bundler`) and run this command in each sub-project to
get started:

``` bash
$ bundle install
```

Run the RSpec suite using `bundle exec`:

``` bash
$ bundle exec rake
```

## Basic Example

``` ruby
require 'riak-client'

# Create a client interface
client = Riak::Client.new

# Create a client that uses Protocol Buffers
client = Riak::Client.new(:protocol => "pbc")

# Automatically balance between multiple nodes
client = Riak::Client.new(:nodes => [
  {:host => '10.0.0.1'},
  {:host => '10.0.0.2', :pb_port => 1234},
  {:host => '10.0.0.3', :pb_port => 5678}
])

# Retrieve a bucket
bucket = client.bucket("doc")  # a Riak::Bucket

# Get an object from the bucket
object = bucket.get_or_new("index.html")   # a Riak::RObject

# Change the object's data and save
object.raw_data = "<html><body>Hello, world!</body></html>"
object.content_type = "text/html"
object.store

# Reload an object you already have
object.reload                  # Works if you have the key and vclock, using conditional GET
object.reload :force => true   # Reloads whether you have the vclock or not

# Access more like a hash, client[bucket][key]
client['doc']['index.html']   # the Riak::RObject

# Create a new object
new_one = Riak::RObject.new(bucket, "application.js")
new_one.content_type = "application/javascript" # You must set the content type.
new_one.raw_data = "alert('Hello, World!')"
new_one.store
```

## Map-Reduce Example

``` ruby
# Assuming you've already instantiated a client, get the album titles for The Beatles
results = Riak::MapReduce.new(client).
                add("artists","Beatles").
                link(:bucket => "albums").
                map("function(v){ return [JSON.parse(v.values[0].data).title]; }", :keep => true).run

p results # => ["Please Please Me", "With The Beatles", "A Hard Day's Night", 
          #     "Beatles For Sale", "Help!", "Rubber Soul",
          #     "Revolver", "Sgt. Pepper's Lonely Hearts Club Band", "Magical Mystery Tour", 
          #     "The Beatles", "Yellow Submarine", "Abbey Road", "Let It Be"]
```

## Riak Search Examples

For more information about Riak Search, see [the Basho wiki](http://wiki.basho.com/Riak-Search.html).

``` ruby
# Create a client, specifying the Solr-compatible endpoint
# When connecting to Riak 0.14 and later, the Solr endpoint configuration option is not necessary.
client = Riak::Client.new :solr => "/solr"

# Search the default index for documents
result = client.search("title:Yesterday") # Returns a vivified JSON object
                                          # containing 'responseHeaders' and 'response' keys
result['response']['numFound'] # total number of results
result['response']['start']    # offset into the total result set
result['response']['docs']     # the list of indexed documents

# Search the 'users' index for documents
client.search("users", "name:Sean")

# Add a document to an index
client.index("users", {:id => "sean@basho.com", :name => "Sean Cribbs"}) # adds to the 'users' index

client.index({:id => "index.html", :content => "Hello, world!"}) # adds to the default index

client.index({:id => 1, :name => "one"}, {:id => 2, :name => "two"}) # adds multiple docs

# Remove document(s) from an index
client.remove({:id => 1})             # removes the document with ID 1
client.remove({:query => "archived"}) # removes all documents matching query
client.remove({:id => 1}, {:id => 5}) # removes multiple docs

client.remove("users", {:id => "sean@basho.com"}) # removes from the 'users' index

# Seed MapReduce with search results
Riak::MapReduce.new(client).
        search("users","email:basho").
        map("Riak.mapValuesJson", :keep => true).
        run

# Detect whether a bucket has auto-indexing
client['users'].is_indexed?

# Enable auto-indexing on a bucket
client['users'].enable_index!

# Disable auto-indexing on a bucket
client['users'].disable_index!
```

## Secondary Index Examples

Riak supports secondary indexes. Secondary indexing, or "2i," gives you the 
ability to tag objects with multiple queryable values at write time, and then
query them later.

* [Using Secondary Indexes](http://docs.basho.com/riak/latest/dev/using/2i/)
* [Secondary Index implementation notes](http://docs.basho.com/riak/latest/dev/advanced/2i/)

### Tagging Objects

Objects are tagged with a hash kept behind the `indexes` method. Secondary index
storage logic is in `lib/riak/rcontent.rb`.

```ruby
object = bucket.get_or_new 'cobb.salad'

# Indexes end with the "_bin" suffix to indicate they're binary or string 
# indexes. They can have multiple values.
object.indexes['ingredients_bin'] = %w{lettuce tomato bacon egg chives}

# Indexes ending with the "_int" suffix are indexed as integers. They can
# have multiple values too.
object.indexes['calories_int'] = [220]

# You must re-save the object to store indexes.
object.store
```

### Finding Objects

Secondary index queries return a list of keys exactly matching a scalar or 
within a range.

```ruby
# The Bucket#get_index method allows querying by scalar...
bucket.get_index 'calories_int', 220 # => ['cobb.salad']

# or range.
bucket.get_index 'calories_int', 100..300 # => ['cobb.salad']

# Binary indexes also support both ranges and scalars.
bucket.get_index 'ingredients_bin', 'tomata'..'tomatz' # => ['cobb.salad']

# The collection from #get_index also provides a continuation for pagination:
c = bucket.get_index 'ingredients_bin', 'lettuce', max_results: 5
c.length # => 5
c.continuation # => "g2gCbQAAA="

# You can use that continuation to get the next page of results:
c2 = bucket.get_index 'ingredients_bin', 'lettuce', max_results: 5, continuation: c.continuation

# More complicated operations may benefit by using the `SecondaryIndex` object:
q = Riak::SecondaryIndex.new bucket, 'ingredients_bin', 'lettuce', max_results: 5

# SecondaryIndex objects give you access to the keys...
q.keys # => ['cobb.salad', 'wedge.salad', 'buffalo_chicken.wrap', ...]

# but can also fetch values for you in parallel.
q.values # => [<RObject {recipes,cobb.salad} ...>, <RObject {recipes,wedge...

# They also provide simpler pagination:
q.has_next_page? # => true
q2 = q.next_page
```

## Riak 2 Data Types

Riak 2 features new distributed data structures: counters, sets, and maps 
(containing counters, flags, maps, registers, and sets).  These are implemented 
by the Riak database as Convergent Replicated Data Types.

Riak data type support requires bucket types to be configured to support each
top-level data type. If you're just playing around, use the 
[Riak Ruby Vagrant](https://github.com/basho-labs/riak-ruby-vagrant) setup to
get started with the appropriate configuration and bucket types quickly.

The examples below presume that the appropriate bucket types are named
`counters`, `maps`, and `sets`; these bucket type names are the client's defaults.
Viewing and changing the defaults is easy:

```ruby
Riak::Crdt::DEFAULT_BUCKET_TYPES[:set] #=> "sets"

Riak::Crdt::DEFAULT_BUCKET_TYPES[:set] = "a_cooler_set"
```

The top-level CRDT types have both immediate and batch mode. If you're doing
multiple writes to a single top-level counter or set, or updating multiple map
entries, batch mode will make fewer round-trips to Riak.

### Counters

Riak 2 integer counters have one operation: increment by an integer.

```ruby
counter = Riak::Crdt::Counter.new bucket, key

counter.value #=> 15

counter.increment

counter.value #=> 16

counter.increment 3

counter.value #=> 19

counter.decrement

counter.value #=> 18
```

Counter operations can be batched:

```ruby
counter.batch do |c|
  c.increment
  c.increment 5
end
```

### Maps

Riak 2 maps can contain counters, flags (booleans), registers (strings), sets, and
other maps.

Maps are similar but distinct from the standard Ruby `Hash`. Entries are
segregated by both name and type, so you can have counters, registers, and sets inside a map that all have the same name.

```ruby
map = Riak::Crdt::Map.new bucket, key

map.counters['potatoes'].value #=> 5
map.sets['potatoes'].include? 'yukon gold' #=> true

map.sets['cacti'].value #=> #<Set: {"saguaro", "prickly pear", "fishhook"}>
map.sets['cacti'].remove 'prickly pear'

map.registers['favorite butterfly'] = 'the mighty monarch'

map.flags['pet cat'] = true

map.maps['atlantis'].registers['location'] #=> 'kennedy space center'

map.counters.delete 'thermometers'
```

Maps are a prime candidate for batched operations:

```ruby
map.batch do |m|
  m.counters['hits'].increment
  m.sets['followers'].add 'basho_elevator'
end
```

### Sets

Sets are an unordered collection of entries.

**PROTIP:** Ruby and Riak Ruby Client both have classes called `Set`. Be careful
to refer to the Ruby version as `::Set` and the Riak client version as
`Riak::Crdt::Set`.

```ruby
set = Riak::Crdt::Set.new bucket, key

set.members #=> #<Set: {"Edinburgh", "Leeds", "London"}>

set.add "Newcastle"
set.remove "London"

set.include? "Leeds" #=> true
```

Sets support batched operations:

```ruby
set.batch do |s|
  s.add "York"
  s.add "Aberdeen"
  s.remove "Newcastle"
end
```

### Client Implementation Notes

The client code for these types is in the `Riak::Crdt` namespace, and mostly
in the `lib/riak/crdt` directory.

## Riak 1.4 Counters

For more information about counters in Riak, see [the Basho wiki](http://docs.basho.com/riak/latest/dev/references/http/counters/).

Counter records are automatically persisted on increment or decrement. The initial default value is 0.

``` ruby
# Firstly, ensure that your bucket is allow_mult set to true
bucket = client.bucket "counters"
bucket.allow_mult = true

# You can create a counter by using the bucket's counter method
counter = bucket.counter("counter-key-here")
counter.increment
=> nil

p counter.value
1
=> 1

# Let's increment one more time and then retrieve it from the database
counter.increment

# Retrieval is similar to creation
persisted_counter = Riak::Counter.new(bucket, "counter-key-here")

p persisted_counter.value
2
=> 2

# We can also increment by a specified number
persisted_counter.increment(20)
p persisted_counter.value
22
=> 22

# Decrement works much the same
persisted_counter.decrement
persisted_counter.value
=> 21

persisted_counter.decrement(6)
persisted_counter.value
=> 15

# Incrementing by anything other than integer will throw an ArgumentError
persisted_counter.increment "nonsense"
ArgumentError: Counters can only be incremented or decremented by integers.
```

That's about it. PN Counters in Riak are distributed, so each node will receive the proper increment/decrement operation. Enjoy using them.


## How to Contribute

* Fork the project on [Github](http://github.com/basho/riak-ruby-client).  If you have already forked, use `git pull --rebase` to reapply your changes on top of the mainline. Example:

    ``` bash
    $ git checkout master
    $ git pull --rebase basho master
    ```

* Copy spec/support/test_server.yml.example to spec/support/test_server.yml and change that file according to your local installation of riak.

* Create a topic branch. If you've already created a topic branch, rebase it on top of changes from the mainline "master" branch. Examples:
  * New branch:

        ``` bash
        $ git checkout -b topic
        ```
  * Existing branch:

        ``` bash
        $ git rebase master
        ```
* Write an RSpec example or set of examples that demonstrate the necessity and validity of your changes. **Patches without specs will most often be ignored. Just do it, you'll thank me later.** Documentation patches need no specs, of course.
* Make your feature addition or bug fix. Make your specs and stories pass (green).
* Run the suite using multiruby or rvm to ensure cross-version compatibility.
* Cleanup any trailing whitespace in your code (try @whitespace-mode@ in Emacs, or "Remove Trailing Spaces in Document" in the "Text" bundle in Textmate). You can use the `clean_whitespace` Rake task if you like.
* Commit, do not mess with Rakefile. If related to an existing issue in the [tracker](http://github.com/basho/ruby-riak-client/issues), include "Closes #X" in the commit message (where X is the issue number).
* Send a pull request to the Basho repository.

## License & Copyright

Copyright &copy;2010-2012 Sean Cribbs and Basho Technologies, Inc.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

## Auxillary Licenses

The included photo (spec/fixtures/cat.jpg) is Copyright &copy;2009 [Sean Cribbs](http://seancribbs.com/), and is licensed under the [Creative Commons Attribution Non-Commercial 3.0](http://creativecommons.org/licenses/by-nc/3.0) license. 
!["Creative Commons"](http://i.creativecommons.org/l/by-nc/3.0/88x31.png)
