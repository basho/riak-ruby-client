module Riak
  class ListBuckets
    def initialize(client, block)
      @client = client
      @block = block
      perform_request
    end

    def perform_request
      @client.backend do |be|
        be.list_buckets &wrapped_block
      end
    end

    private

    def wrapped_block
      proc do |bucket_name|
        bucket = @client.bucket bucket_name
        @block.call[bucket]
      end
    end
  end
end
