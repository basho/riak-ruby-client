require 'riak/index_collection'
module Riak
  class SecondaryIndex
    include Util::Translation
    include Client::FeatureDetection

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

      validate_options
    end

    def get_server_version
      @client.backend{|b| b.send :get_server_version }
    end

    # Start the 2i fetch operation
    def fetch
    end

    # Get the array of matched keys
    def keys(&block)
      @collection ||=
        @client.backend do |b|
          b.get_index @bucket, @index, @query, @options, &block
        end
    end

    # Get the array of values
    def values
      @values ||= @bucket.get_many(self.keys).values
    end

    # Get a new SecondaryIndex fetch for the next page
    def next_page
      raise t('index.no_next_page') unless keys.continuation

      self.class.new(@bucket, 
                     @index, 
                     @query, 
                     @options.merge(:continuation => keys.continuation))
    end

    # Determine whether a SecondaryIndex fetch has a next page available
    def has_next_page?
      !!keys.continuation
    end

    private
    def validate_options
      raise t('index.pagination_not_available') if paginated? && !index_pagination?
      raise t('index.return_terms_not_available') if @options[:return_terms] && !index_return_terms?
      raise t('index.include_terms_is_wrong') if @options[:include_terms]

      # raise t('index.streaming_not_available') if @options[:stream] && !index_streaming?
    end

    def paginated?
      @options[:continuation] || @options[:max_results]
    end
  end
end
