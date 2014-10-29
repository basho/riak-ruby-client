require 'riak/bucket_typed/bucket'

module Riak
  class BucketType
    attr_reader :client, :name

    # Create a bucket type manually
    def initialize(client, name)
      @client, @name = client, name
    end

    def bucket(bucket_name)
      BucketTyped::Bucket.new client, bucket_name, self
    end
  end
end
