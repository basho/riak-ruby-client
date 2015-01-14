require 'riak'

module Riak
  # Provides a predictable and useful interface to bucket properties. Allows
  # reading, reloading, and setting new values for bucket properties.
  class BucketProperties
    attr_reader :client
    attr_reader :bucket

    # Create a properties object for a bucket (including bucket-typed buckets).
    # @param [Riak::Bucket, Riak::BucketTyped::Bucket] bucket
    def initialize(bucket)
      @bucket = bucket
      @client = bucket.client
    end

    # Clobber the cached properties, and reload them from Riak.
    def reload
      @cached_props = nil
      cached_props
      true
    end

    # Write bucket properties and invalidate the cache in this object.
    def store
      client.backend do |be|
        be.set_bucket_props bucket, cached_props, type_argument
      end
      @cached_props = nil
      return true
    end

    # Take bucket properties from a given {Hash} or {Riak::BucketProperties} 
    # object.
    # @param [Hash<String, Object>, Riak::BucketProperties] other
    def merge!(other)
      cached_props.merge! other
    end

    # Convert the cached properties into a hash for merging.
    # @return [Hash<String, Object>] the bucket properties in a {Hash}
    def to_hash
      cached_props
    end

    # Read a bucket property
    # @param [String] property_name
    # @return [Object] the bucket property's value
    def [](property_name)
      cached_props[property_name.to_s]
    end

    # Write a bucket property
    # @param [String] property_name
    # @param [Object] value
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
