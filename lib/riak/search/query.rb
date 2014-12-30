require 'riak/search'

module Riak::Search
  class Query
    attr_accessor :rows
    attr_accessor :start

    attr_accessor :sort
    attr_accessor :filter

    attr_accessor :df
    attr_accessor :op
    attr_accessor :fl

    attr_accessor :presort

    def initialize(client, index, term, options={  })
      @client = client
      validate_index index
      @term = term
      @options = options.symbolize_keys

      set_defaults
      consume_options
    end

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

      @presort = @options[:presort] if @options[:presort]
    end

    def prepare_options
      configured_options = { 
        rows: @rows,
        start: @start,
        sort: @sort,
        filter: @filter,
        df: @df.join(' '),
        op: @op,
        fl: @fl,
        presort: @presort
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
