---
title: Key-Value
---
Key-value operations in Riak use a few different kinds of object:

* A **bucket type** is a set of configration information used to read and write
  values in Riak. Bucket types are complex and can be unintuitive, so
  [please read the bucket type documentation][1].
* A **bucket** is a named collection of keys. It's similar to a table in a SQL
  database: it has a name that's a string, zero or more members, and members
  can be quickly looked up by their key (primary key in SQL).
* A **key** is a unique string name for something in a bucket. Think of them
  like a SQL primary key that's a string.
* A **value** is a large binary object that is addressed by a bucket type,
  bucket, and key. It works similarly to a BLOB column in SQL. Riak objects
  can have more than one value, which requires conflict resolution.

For more about buckets, keys, and values, read the [object/key operations][2]
documentation.

[1]: http://docs.basho.com/riak/latest/dev/advanced/bucket-types/
[2]: http://docs.basho.com/riak/latest/dev/using/basics/

## tl;dr

``` ruby
require 'riak'

# Create a client interface
client = Riak::Client.new

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

## Objects

Riak's key-value interface maniuplates objects. You can think of an object as:

```ruby
  {bucket type, bucket, key, metadata, values}
```

A bucket type and bucket identify a collection of objects, and the set of
bucket type, bucket, and key identify a single object.

In the Ruby client, a Riak object is represented by a `Riak::RObject` instance.

```ruby
robject = bucket['S. S. Boatname']
robject.class #=> Riak::RObject
```

### Creating Objects

You have a few choices when insantiating an object.

Given a bucket, you can use the `RObject` constructor to create a new object:

```ruby
Riak::RObject.new bucket, 'Son of Boatname'
```

If you use the `Bucket#new` method, the `RObject` is created with a
`content_type` of `application/json` for you:

```ruby
bucket.new 'Son of Boatname'
```

If you want Riak to pick a key for an object for you, create one without
specifying a key:

```ruby
# these both work
robject = Riak::RObject.new bucket, nil
robject = bucket.new

robject.store
robject.key #=> "GB8fW6DDZtXogK19OLmaJf247DN"
```

### Loading Objects

You can load an object if you know its key. If loading the object fails, this
will raise a `Riak::FailedRequest` error with the `not_found?` flag set.

```ruby
bucket['S. S. Boatname']
bucket.get 'S.S. Boatname'
```

If you want to load or create an object with a given key, you can use
`Bucket#get_or_new` to do it:

```ruby
bucket.get_or_new 'Revenge of Boatname'
```

### Manipulating and Storing Objects

#### Serializing and Deserializing Data

Frequently, you'll store objects you want to be serialized and deserialized
for you. Set an appropriate content-type and use the `#data` accessors:

```ruby
robject.content_type = 'application/json'
robject.data = {
    processor: 'MSP-430',
    sensors: %w{range binocular video},
    motor: "trolling motor",
    length: 137.16
}
robject.store # serializes the Ruby hash to JSON
robject.raw_data #=> "{\"processor\": \"MSP-430\"...
robject.data #=> {"processor" => "MSP-430",...
```

Out of the box, the Ruby client supports serializing and deserializing these
content-types:

* `text/plain`: string data only
* `application/json`: uses `MultiJson`
* `application/x-ruby-marshal`: uses `Marshal` in the Ruby core
* `text/yaml`, `text/x-yaml`, `application/yaml`, `application/x-yaml`: use
  `YAML` in the Ruby standard library.

Support for other content-types can be added: write a module with `dump(object)`
and `load(string)` methods, and configure it with the `Riak::Serializers[]`
method. For an example, note how the `TextPlain` and `ApplicationJSON`
serializers are written and configured in the [`Riak::Serializer` module.][1]

[1]: https://github.com/basho/riak-ruby-client/blob/62551f1873f50d40a004b9a27a282bb7e88be329/lib/riak/serializers.rb#L34
