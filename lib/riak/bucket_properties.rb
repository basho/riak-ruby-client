require 'riak'

module Riak
  # Provides a predictable and useful interface to bucket properties. Allows
  # reading, reloading, and setting new values for bucket properties.
  class BucketProperties
    attr_reader :client
    attr_reader :bucket

    def initialize(client, bucket)
      @client = client
      @bucket = bucket
    end

    # Clobber the cached properties, and reload them from Riak.
    def reload
      @cached_props = nil
      cached_props
      true
    end

    def store
      client.backend do |be|
        be.set_bucket_props bucket, cached_props, type_argument
      end
    end

    # Read a bucket property
    def [](property_name)
      cached_props[property_name.to_s]
    end

    # Write a bucket property
    def []=(property_name, value)
      cached_props[property_name.to_s] = value
    end

    private
    def cached_props
      @cached_props ||= client.backend do |be|
        be.get_bucket_props bucket, type_option
      end
    end

    def type_argument
      return nil unless bucket.needs_type?
      bucket.type.name
    end

    def type_option
      return Hash.new unless bucket.needs_type?
      { type: bucket.type.name }
    end
  end
end
