require 'riak/index_collection'
module Riak
  class SecondaryIndex
    include Util::Translation

    # Create a Riak Secondary Index operation
    # @param [Bucket] the {Riak::Bucket} we'll query against
    # @param [String] the index name
    # @param [String,Integer,Range<String,Integer>] a single value or
    #   range of values to query for
    def initialize(bucket, index, query, options={})
      @bucket = bucket
      @client = @bucket.client
      @index = index
      @query = query
      @options = options
    end

    # Start the 2i fetch operation
    def fetch
    end

    # Get the array of matched keys
    def keys
      @client.backend do |b|
        b.get_index @bucket, @index, @query, @options
      end
    end

    # Get the array of values
    def values
      pp k = self.keys
      @bucket.get_many(k).values
    end
  end
end
