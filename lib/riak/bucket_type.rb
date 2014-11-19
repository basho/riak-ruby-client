require 'riak/bucket_typed/bucket'

module Riak
  # A representation of a bucket type
  class BucketType
    attr_reader :client, :name

    # The name of Riak's default bucket type.
    DEFAULT_NAME = 'default'

    # Create a bucket type object manually.
    # @param [Client] client the {Riak::Client} for this bucket type
    # @param [String] name the name of this bucket type
    def initialize(client, name)
      @client, @name = client, name
    end

    # Is this bucket type the default?
    # @return [Boolean]
    def default?
      name == DEFAULT_NAME
    end

    # Get a bucket of this type
    # @param [String] bucket_name the name of this bucket
    def bucket(bucket_name)
      BucketTyped::Bucket.new client, bucket_name, self
    end

    # Pretty prints the bucket for `pp` or `pry`.
    def pretty_print(pp)
      pp.object_group self do
        pp.breakable
        pp.text "name=#{name}"
      end
    end

    # Get the properties of this bucket type
    # @return [Hash<Symbol,Object>]
    def properties
      @properties ||= client.backend do |be|
        be.get_bucket_type_props name
      end
    end
    alias :props :properties

  end
end
