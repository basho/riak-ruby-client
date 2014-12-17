require 'riak/search'
require 'riak/errors/search_error'

module Riak::Search
  class Index
    attr_reader :name

    def initialize(client, name)
      @client = client
      @name = name
    end

    def exists?
      !!index_data
    end

    def n_val
      index_data[:n_val]
    end

    def schema
      index_data[:schema]
    end

    def create!(schema = nil, n_val = nil)
      raise Riak::SearchError::IndexExistsError.new name if exists?

      @client.backend do |b|
        b.create_search_index name, schema, n_val
      end

      @index_data = nil
    end

    private
    def index_data
      return @index_data if defined?(@index_data) && @index_data

      id = nil

      begin
        id = @client.backend do |b|
          b.get_search_index name
        end.index
      rescue Riak::ProtobuffsFailedRequest => e
        return nil if e.not_found?
        raise e
      end

      id = id.first if id.is_a? Array

      return @index_data = id
    end
  end
end
