module Riak
  class ListBuckets
    def initialize(client, options, block)
      @client = client
      @block = block
      @options = options
      perform_request
    end

    def perform_request
      @client.backend do |be|
        be.list_buckets @options, &wrapped_block
      end
    end

    private

    def wrapped_block
      proc do |bucket_names|
        next if bucket_names.nil?
        bucket_names.each do |bucket_name|
          bucket = @client.bucket bucket_name
          @block.call bucket
        end
      end
    end
  end
end
