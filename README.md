# Riak Ruby Client (riak-client)

`riak-client` is a rich Ruby client/toolkit for Riak, Basho's
distributed database that contains a basic wrapper around typical
operations, including bucket manipulation, object CRUD, link-walking,
and map-reduce.

Exhaustive documentation is available at
http://basho.github.io/riak-ruby-client/ , and API documentation can be
read at http://www.rubydoc.info/gems/riak-client/frames .

## Dependencies

Ruby 1.9.3, 2.0, 2.1, and 2.2 are supported. JRuby in 1.9 and 2.0 modes are
also supported. `riak-client` is not compatible with Ruby 1.8.

In JRuby 1.7.13, OCSP validation is absent, and CRL validation always
fails. [This issue is being tracked][1] and this document will be updated when
it is fixed. Additionally, client certificate authentication doesn't work in
JRuby. [This issue is also being tracked][2], and this document will be updated
when it works.

[1]: https://github.com/jruby/jruby-openssl/issues/5
[2]: https://github.com/basho/riak_api/issues/65

`riak-client` requires beefcake, cert_validator, i18n, innertube, and
multi_json.

Development dependencies are handled with bundler. Install bundler
(`gem install bundler`) and run this command to get started:

```bash
$ bundle install
```

Run the RSpec suite using `bundle exec`:

```bash
$ bundle exec rake
```

## Basic Example

```ruby
require 'riak'

# Create a client interface
client = Riak::Client.new

# Create a client that uses secure Protocol Buffers
client = Riak::Client.new(authentication: {
      # certificate authority to validate the server cert
      ca_file: '/home/zedo/ca.crt',

      # username, required
      user: 'zedo',

      # password for password-based authentication
      password: 'catnip',

      # client-cert authentication parameters support filenames,
      # OpenSSL-compatible string data, or properly initialized
      # OpenSSL objects
      client_ca: '/home/zedo/ca.crt',
      cert: File.read '/home/zedo/zedo.crt',
      key: OpenSSL::PKey::RSA.new(File.read '/home/zedo/zedo.key')
    })

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

## Bucket Types

Riak 2 uses [bucket types][1] to enable groups of similar buckets to share
properties, configuration, and to namespace values within those buckets. Bucket
type support is integral to how CRDTs work.

[1]: http://docs.basho.com/riak/latest/dev/advanced/bucket-types

In versions 2.2.0 and newer of this client, bucket types have a first-class
representation, and can be used to create `BucketTyped::Bucket` objects that are
namespaced differently from regular `Riak::Bucket` objects.

```ruby
# This example assumes you have a "beverages" bucket type.
beverages = client.bucket_type 'beverages'

coffees = beverages.bucket 'coffees'
untyped_coffees = client.bucket 'coffees'

chapadao = coffees.new 'chapadao'
chapadao.data = "Chapadao de Ferro"
chapadao.store # stores this in the "beverages" bucket type

untyped_coffees.get 'chapadao' # raises error, not found
coffees.get 'chapadao' # succeeds

chapadao.reload # succeeds

untyped_coffees.delete 'chapadao' # silently fails to delete it
chapadao.delete # deletes it
coffees.delete 'chapadao' # deletes it
```

Client 2.0 and 2.1 code that uses the `type` argument to methods still works:

```ruby
coffees = client.bucket 'coffees'

chapadao = coffees.new 'chapadao'
chapadao.data = "Chapadao de Ferro"
chapadao.store type: 'beverages' # stores this in the "beverages" bucket type

coffees.get 'chapadao' # raises error, not found
coffees.get 'chapadao', type: 'beverages' # succeeds

chapadao.reload # raises error, not found
chapadao.reload type: 'beverages' # succeeds

chapadao.delete # silently fails to delete it
coffees.delete 'chapadao' # silently fails to delete it

chapadao.delete type: 'beverages' # deletes it
coffees.delete 'chapadao', type: 'beverages' # deletes it
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

This client supports the new Riak Search 2 (codenamed "Yokozuna"). For more information about Riak Search, see [the Riak documentation](http://docs.basho.com/riak/latest/dev/using/search/).

This documentation assumes there's a `yokozuna` bucket type created and activated.

``` ruby
# Create a client and bucket.
client = Riak::Client.new
bucket_type = client.bucket_type 'yokozuna'
bucket = bucket_type.bucket 'pizzas'

# Create an index and add it to a typed bucket. Setting the index on the bucket
# may fail until the index creation has propagated.
index = Riak::Search::Index.new client, 'pizzas'
index.exist? #=> false
index.create!
client.set_bucket_props bucket, {search_index: 'pizzas'}, 'yokozuna'

# Store some records for indexing
meat = bucket.new 'meat'
meat.data = {toppings_ss: %w{pepperoni ham sausage}}
meat.store type: 'yokozuna'

hawaiian = bucket.new 'hawaiian'
hawaiian.data = {toppings_ss: %w{ham pineapple}}
hawaiian.store type: 'yokozuna'

# Search the pizzas index for hashes that have a "ham" entry in the toppings_ss array
query = Riak::Search::Query.new client, index, 'toppings_ss:ham'
query.rows = 5 # return the first five pizzas

result = query.results # returns a ResultsCollection object
result.length # number of results returned
result.num_found # total number of results found, including ones not returned

pizza_result = result.first # a ResultDocument of the first pizza
pizza_result.score # score of the match
pizza_result.key # also pizza.bucket and pizza.bucket_type

pizza = pizza_result.robject # load the actual RObject for the match
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

Top-level CRDT types accept `nil` as a key. This allows Riak to assign a random
key for them.

Deleting CRDTs requires you to use the key-value API for the time being.

```ruby
brews = Riak::Crdt::Set.new bucket, 'brews'
brews.add 'espresso'
brews.add 'aeropress'

bucket.delete brews.key, type: brews.bucket_type
```


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

Frequently, you might want a map with a Riak-assigned name instead of one you
come up with yourself:

```ruby
map = Riak::Crdt::Map.new bucket, nil

map.registers['coat_pattern'] = 'tabby'

map.key #=> "2do4NvcurWhXYNQg8HoIR9zedJV"
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

For more information about 1.4-style counters in Riak, see [the Basho documentation](http://docs.basho.com/riak/latest/dev/references/http/counters/).

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

## Instrumentation

The Riak client has built-in event hooks for all major over-the-wire operations including:

* riak.list_buckets
* riak.list_keys
* riak.set_bucket_props
* riak.get_bucket_props
* riak.clear_bucket_props
* riak.get_index
* riak.store_object
* riak.get_object
* riak.reload_object
* riak.delete_object
* riak.map_reduce
* riak.ping

Events are propogated using [ActiveSupport::Notifications](http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html), provided by the [Instrumentable](https://github.com/siyegen/instrumentable) gem.

### Enabling

Instrumentation is opt-in. If `instrumentable` is not available, instrumentation will not be available. To turn on instrumentation, simply require the `instrumentable` gem in your app's Gemfile:

```ruby
gem 'instrumentable', '~> 1.1.0'
```

Then, to subscribe to events:

```ruby
ActiveSupport::Notifications.subscribe(/^riak\.*/) do |name, start, finish, id, payload|
  name    # => String, name of the event (such as 'riak.get_object' from above)
  start   # => Time, when the instrumented block started execution
  finish  # => Time, when the instrumented block ended execution
  id      # => String, unique ID for this notification
  payload # => Hash, the payload
end
```

The payload for each event contains the following keys:

* `:client_id`: The client_id of the Riak client
* `:_method_args`: The array of method arguments for the instrumented method. For instance, for `riak.get_object`, this value would resemble `[<Riak::Bucket ...>, 'key', {}]`

## Running Specs

We aim to have a comprehensive and fast set of tests, implemented using a modern,
well-supported version of RSpec. These tests include both unit specs for
individual classes, and integration specs that ensure the client works properly
with an actual Riak instance.

The [Riak Ruby Vagrant][1] virtual machine's Riak configuration is normally
used to test this client in development. Once it's up and running, configure
the Ruby `test_client.yml` on the host machine to connect to `pb_port: 17017`
and test away.

[1]: https://github.com/basho-labs/riak-ruby-vagrant

Configuring the Riak node the tests connect to is done via the
`spec/support/test_client.yml` file, which is loaded into a Ruby hash with
symbolized keys, and passed to `Riak::Client.new`.

```yml
# test_client.yml
pb_port: 10017
# UNCOMMENT AUTHENTICATION SECTION WHEN RIAK HAS SECURITY ENABLED
# authentication:
#   user: user
#   password: password
#   ca_file: spec/support/certs/ca.crt
```

### Spec dependencies

Specs depend on the following Riak configurations:

* The **LevelDB backend** is necessary for testing secondary indexes.
* **allow_mult** is required for many features: conflict resolution, and legacy
  counters among them.
* **Riak Search 2.0** ("Yokozuna") must be configured for testing full-text
  search.

The following bucket types are used during testing:

```shell
riak-admin bucket-type create counters '{"props":{"datatype":"counter", "allow_mult":true}}'
riak-admin bucket-type create other_counters '{"props":{"datatype":"counter", "allow_mult":true}}'
riak-admin bucket-type create maps '{"props":{"datatype":"map", "allow_mult":true}}'
riak-admin bucket-type create sets '{"props":{"datatype":"set", "allow_mult":true}}'
riak-admin bucket-type create yokozuna '{"props":{}}'

riak-admin bucket-type activate other_counters
riak-admin bucket-type activate counters
riak-admin bucket-type activate maps
riak-admin bucket-type activate sets
riak-admin bucket-type activate yokozuna
```

Client tests run both with and without security enabled, as we have to test
several positive and negative paths. The tests broadly depend on these users
and roles:

```shell
riak-admin security add-user user password=password
riak-admin security add-user certuser

riak-admin security add-source user 0.0.0.0/0 password
riak-admin security add-source certuser 0.0.0.0/0 certificate

riak-admin security grant riak_kv.get,riak_kv.put,riak_kv.delete,\
riak_kv.index,riak_kv.list_keys,riak_kv.list_buckets,\
riak_core.get_bucket,riak_core.set_bucket,\
riak_core.get_bucket_type,riak_core.set_bucket_type,\
search.admin,search.query,riak_kv.mapreduce on any to user
```

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

Copyright &copy;2010-2016 Sean Cribbs and Basho Technologies, Inc.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

## Auxillary Licenses

The included photo (spec/fixtures/cat.jpg) is Copyright &copy;2009 [Sean Cribbs](http://seancribbs.com/), and is licensed under the [Creative Commons Attribution Non-Commercial 3.0](http://creativecommons.org/licenses/by-nc/3.0) license.
!["Creative Commons"](http://i.creativecommons.org/l/by-nc/3.0/88x31.png)

## Contributors

Thank you to all of our contributors!

* [Adam Hunter](https://github.com/adamhunter)
* [akm](https://github.com/akm)
* [Alexander Lang](https://github.com/langalex)
* [Alex Moore](https://github.com/alexmoore)
* [André Silva](https://github.com/andrelrs)
* [Ashley Woodard](https://github.com/ashley-woodard)
* [batasrki](https://github.com/batasrki)
* [benmills](https://github.com/benmills)
* [Brian Kaney](https://github.com/bkaney)
* [Bryce Kerley](https://github.com/bkerley)
* [Carl Hall](https://github.com/thecarlhall)
* [Charl Matthee](https://github.com/charl)
* [dan](https://github.com/dan)
* [Daniel Reverri](https://github.com/dreverri)
* [Dave Perrett](https://github.com/recurser)
* [David Czarnecki](https://github.com/czarneckid)
* [dn](https://github.com/dndn)
* Duff OMelia
* [Elias Levy](https://github.com/eliaslevy)
* [Eric Cestari](https://github.com/cstar)
* [Eric Redmond](https://github.com/coderoshi)
* [Hidekazu Tanaka](https://github.com/holidayworking)
* [Hiroyasu Ohyama](https://github.com/userlocalhost2000)
* [Jace](https://github.com/jace)
* [Jack Dempsey](https://github.com/jackdempsey)
* Jay Adkisson
* [Jeff Pollard](https://github.com/Fluxx)
* [Joe DeVivo](https://github.com/joedevivo)
* [John Axel Eriksson](https://github.com/johnae)
* [John Leach](https://github.com/johnl)
* [John Lynch](https://github.com/johnthethird)
* Jordan Goldstein
* [Josh Nichols](https://github.com/technicalpickles)
* [Justin Pease](https://github.com/jpease)
* [Kazuhiro Suzuki](https://github.com/ksauzz)
* [Kyle Kingsbury](https://github.com/aphyr)
* [Lee Jensen](https://github.com/outerim)
* [Luke Bakken](https://github.com/lukebakken)
* [Marco Campana](https://github.com/marcocampana)
* [Mat Brown](https://github.com/outoftime)
* [Mathias Meyer](https://github.com/roidrage)
* [Michael Sullivan](https://github.com/msullivan)
* [Misha Gorodnitzky](https://github.com/misaka)
* [Myron Marston](https://github.com/myronmarston)
* [Nathaniel Talbott](https://github.com/ntalbott)
* [Nicholas Rowe](https://github.com/NicholasRowe)
* [Nicolas Fouché](https://github.com/nfo)
* [oleg dashevskii](https://github.com/be9)
* [PatrickMa](https://github.com/patrickmaciel)
* [Peter Garbers](https://github.com/petergarbers)
* [Randy Secrist](https://github.com/randysecrist)
* [Rusty Klophaus](https://github.com/rustyio)
* [Ryan Daigle](https://github.com/rwdaigle)
* [Sam Aarons](https://github.com/saarons)
* [Sean Cribbs](https://github.com/seancribbs)
* Sebastian Röbke
* [Shay Frendt](https://github.com/shayfrendt)
* [Srdjan Pejic](https://github.com/batasrki)
* [StabbyCutyou](https://github.com/StabbyCutyou)
* [Stefan Sprenger](https://github.com/flippingbits)
* Technorama, Ltd
* [Tyler Hunt](https://github.com/tylerhunt)
* [Wagner Camarao](https://github.com/wcamarao)
* [Woody Peterson](https://github.com/woahdae)
* [Zshawn Syed](https://github.com/zsyed91)
