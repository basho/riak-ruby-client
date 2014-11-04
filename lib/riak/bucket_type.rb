require 'riak/bucket_typed/bucket'

module Riak
  # A representation of a bucket type
  class BucketType
    attr_reader :client, :name

    # Create a bucket type object manually.
    # @param [Client] client the {Riak::Client} for this bucket type
    # @param [String] name the name of this bucket type
    def initialize(client, name)
      @client, @name = client, name
    end

    # Get a bucket of this type
    # @param [String] bucket_name the name of this bucket
    def bucket(bucket_name)
      BucketTyped::Bucket.new client, bucket_name, self
    end
  end
end
