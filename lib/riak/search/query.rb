require 'riak/search'

module Riak::Search
  class Query
    attr_accessor :rows

    attr_accessor :fl
    attr_accessor :df

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
      @fl = %w{_yz_rb _yz_rk _yz_rt score}
      @df = %w{text}
      @start = 0
      @rows = nil
    end

    def consume_options
      @start = @options[:start] if @options[:start]
      @rows = @options[:rows] if @options[:rows]
      @fl = @options[:fl] if @options[:fl]
      @df = @options[:df] if @options[:df]
    end

    def prepare_options
      @options.merge rows: @rows, fl: @fl.join(' '), df: @df.join(' ')
    end

    def raw_results
      @client.backend do |be|
        be.search index_name, @term, prepare_options
      end
    end
  end
end
