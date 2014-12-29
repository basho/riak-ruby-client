require 'riak/search'

module Riak::Search
  class Query
    attr_accessor :rows

    attr_accessor :df

    def initialize(client, index, term, options={  })
      @client = client
      @index = index
      @term = term
      @options = options.symbolize_keys

      validate_arguments
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

    def validate_arguments
      unless @index.is_a?(String) || @index.is_a?(Riak::Search::Index)
        raise IndexArgumentError.new @index
      end
    end

    def set_defaults
      @fl = %w{_yz_rb _yz_rk _yz_rt score}
      @df = %w{text}
    end

    def consume_options
      @rows = @options[:rows]
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
