# Riak Ruby Client (riak-client) [![Build Status](https://secure.travis-ci.org/basho/riak-ruby-client.png)](http://travis-ci.org/basho/riak-ruby-client)

`riak-client` is a rich Ruby client/toolkit for Riak, Basho's
distributed database that contains a basic wrapper around typical
operations, including bucket manipulation, object CRUD, link-walking,
and map-reduce.

## Dependencies

`riak-client` requires i18n, builder, beefcake, and multi_json. For
higher performance on HTTP requests, install the 'excon' gem. The
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
require 'riak'

# Create a client interface
client = Riak::Client.new

# Create a client interface that uses Excon
client = Riak::Client.new(:http_backend => :Excon)

# Create a client that uses Protocol Buffers
client = Riak::Client.new(:protocol => "pbc")

# Automatically balance between multiple nodes
client = Riak::Client.new(:nodes => [
  {:host => '10.0.0.1'},
  {:host => '10.0.0.2', :pb_port => 1234},
  {:host => '10.0.0.3', :http_port => 5678}
])

# Retrieve a bucket
bucket = client.bucket("doc")  # a Riak::Bucket

# Get an object from the bucket
object = bucket.get_or_new("index.html")   # a Riak::RObject

# Change the object's data and save
object.data = "<html><body>Hello, world!</body></html>"
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
new_one.data = "alert('Hello, World!')"
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

## How to Contribute

* Fork the project on [Github](http://github.com/basho/riak-ruby-client).  If you have already forked, use `git pull --rebase` to reapply your changes on top of the mainline. Example:

    ``` bash
    $ git checkout master
    $ git pull --rebase basho master
    ```
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
