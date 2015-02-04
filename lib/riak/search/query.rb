require 'riak/search'

module Riak::Search
  # A {Riak::Search::Query} wraps a Solr query for Riak Search 2.
  class Query

    # @!attribute rows
    # @return [Numeric] the number of rows to return from the query
    attr_accessor :rows

    # @!attribute start
    # @return [Numeric] the offset into the total result set to get results for
    attr_accessor :start

    # @!attribute sort
    # @return [String] how Solr should sort the result set
    attr_accessor :sort

    # @!attribute filter
    # @return [String] have Solr filter the results prior to returning them
    attr_accessor :filter

    # @!attribute df
    # @return [Array<String>] default fields for Solr to search
    attr_accessor :df

    # @!attribute op
    # @return [String] Solr search operator
    attr_accessor :op

    # @!attribute fl
    # @return [Array<String>] fields for Solr to return
    attr_accessor :fl

    # @!attribute [r] term
    # @return [String] the term to query
    attr_reader :term

    # Initializes a query object.
    #
    # @param [Riak::Client] client the client connected to the Riak cluster
    # @param [String,Riak::Search::Index] index the index to query, either a
    #   {Riak::Search::Index} instance or a {String}
    # @param [String] term the query term
    # @param [Hash] options a hash of options to quickly set attributes
    def initialize(client, index, term, options = {  })
      @client = client
      validate_index index
      @term = term
      @options = options.symbolize_keys

      set_defaults
      consume_options
    end

    # Get results from the query. Performs the query when called the first time.
    #
    # @return [Riak::Search::ResultCollection] collection of results
    def results
      return @results if defined? @results

      @results = ResultCollection.new @client, raw_results
    end

    private

    def index_name
      return @index if @index.is_a? String
      return @index.name
    end

    def validate_index(index)
      if index.is_a? String
        index = Riak::Search::Index.new @client, index
      end

      unless index.is_a? Riak::Search::Index
        raise Riak::SearchError::IndexArgumentError.new index
      end

      unless index.exists?
        raise Riak::SearchError::IndexNonExistError.new index.name
      end

      @index = index
    end

    def set_defaults
      @rows = nil
      @start = nil

      @sort = nil
      @filter = nil

      @df = %w{text}
      @op = nil
      @fl = %w{_yz_rb _yz_rk _yz_rt score}

      @presort = nil
    end

    def consume_options
      @rows = @options[:rows] if @options[:rows]
      @start = @options[:start] if @options[:start]

      @sort = @options[:sort] if @options[:sort]
      @filter = @options[:filter] if @options[:filter]

      @df = @options[:df] if @options[:df]
      @op = @options[:op] if @options[:op]
      @fl = @options[:fl] if @options[:fl]
    end

    def prepare_options
      configured_options = {
        rows: @rows,
        start: @start,
        sort: @sort,
        filter: @filter,
        df: @df.join(' '),
        op: @op,
        fl: @fl
      }
      @options.merge configured_options
    end

    def raw_results
      @client.backend do |be|
        be.search index_name, @term, prepare_options
      end
    end
  end
end
