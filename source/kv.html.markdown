---
title: Key-Value
---
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

Riak's key-value system stores objects. You can think of an object as:

```ruby
  {bucket type, bucket, key, metadata, value}
```

A bucket type and bucket identify a collection of objects, and the set of
bucket type, bucket, and key identify a single object.
