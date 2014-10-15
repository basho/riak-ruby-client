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

Get an object:

``` ruby
# get an object
object = bucket.get 'index.html'
object = bucket['index.html']

# get or create an object
object = bucket.get_or_new 'index.html'

# create a new object
object = bucket.new 'index.html'

# change the object's data and save
object.raw_data = "<html><body>Hello, world!</body></html>"
object.content_type = "text/html"
object.store

# reload an object you already have the vclock of
object.reload

# reload an object without the vclock
object.reload :force => true
```

## Objects

Riak's key-value interface maniuplates objects. You can think of an object as
a tuple:

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

#### Raw Data, No Serialization

Use the `RObject#raw_data` accessors to manipulate the raw blob/string that
represents the value of a Riak object. The client will not transform or parse
this data.

```ruby
robject.content_type = 'image/jpeg'
robject.raw_data = File.read 'cat.jpg'
robject.store
```

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

##### Other Content Types

Support for other content-types can be added: write a module with `dump(object)`
and `load(string)` methods, and configure it with the `Riak::Serializers[]`
method. For an example, note how the `TextPlain` and `ApplicationJSON`
serializers are written and configured in the [`Riak::Serializer` module.][1]

[1]: https://github.com/basho/riak-ruby-client/blob/62551f1873f50d40a004b9a27a282bb7e88be329/lib/riak/serializers.rb#L34

## Content and Conflict

Riak objects can have more than one value. If you have an eventually-consistent
bucket (i.e. not strongly consistent) with `allow_mult` enabled and
`last_write_wins` disabled ([choose wisely][2], [it's important][1]), multiple
values for a given object are common.

[1]: http://aphyr.com/posts/285-call-me-maybe-riak
[2]: http://docs.basho.com/riak/latest/dev/using/conflict-resolution/

Resolving conflicts can be tricky! [Riak's CRDT implementation][1] and how the
[Ruby client CRDT support][2] works may lead you to a better solution than
relying on client-side conflict resolution.

[1]: http://docs.basho.com/riak/latest/dev/using/data-types/
[2]: /crdt.html

The `Riak::RContent` class handles properties of an individual value. Without
conflict, [`Riak::RObject` delegates many of its apparent properties][1] to an
`RContent` instance. With conflict, attempts to access these properties will
raise a `Riak::Conflict` error.

[1]: https://github.com/basho/riak-ruby-client/blob/62551f1873f50d40a004b9a27a282bb7e88be329/lib/riak/robject.rb#L56-L64

```ruby
robject.conflict? #=> true
robject.raw_data # raises Riak::Conflict
```

### Manual Conflict Resolution

If a `Riak::RObject` is in conflict, you can resolve the conflict by setting its
`siblings` array to an array with one element. Ideally, you'll loop through the
array of siblings and accumulate a correct one.

In this case, assume we have objects that store a single number, and we want to
resolve them to the maximum.

```ruby
robject.conflict? #=> true

max_sibling = robject.siblings.inject do |max_sibling, current_sibling|
    next max_sibling if max_sibling.data > current_sibling.data
    next current_sibling
end

robject.siblings = [max_sibling.dup]
robject.store

robject.reload
robject.conflict? #=> false
```

### Conflict Resolution Callbacks

`Riak::RObject` also has `on_conflict` hooks. These hooks work much like manual
conflict resolution. Register them with [`Riak::RObject.on_conflict`][1], and
trigger then on a conflicted object with `RObject#attempt_conflict_resolution`.

[1]: http://www.rubydoc.info/gems/riak-client/Riak/RObject.on_conflict

With the same scenario as above:

```ruby
Riak::RObject.on_conflict do |robject|
    max_sibling = robject.siblings.inject do |max_sibling, current_sibling|
        next max_sibling if max_sibling.data > current_sibling.data
        next current_sibling
    end

    robject.siblings = [max_sibling.dup]
end

object.conflict? #=> true
object.attempt_conflict_resolution
object.store
object.conflict? #=> false
```

You can have multiple conflict resolution callbacks. If they return `nil` the
next one in the list will fire. If you want different callbacks for different
buckets, simply make the first thing they do check if the bucket is the expected
one:

```ruby
Riak::RObject.on_conflict do |robject|
  next nil unless robject.bucket.name == 'robots'
  # actually resolve the robot conflict
end
```

If none of the handlers resolve the conflict, the object will remain in
conflict.
