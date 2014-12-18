require 'riak/search'
require 'riak/errors/search_error'

module Riak::Search
  class Schema
    attr_reader :name

    def initialize(client, name)
      @client = client
      @name = name
    end

    def exists?
      !!schema_data
    end

    def content
      schema_data.content
    end

    def create!(content)
      raise Riak::SearchError::SchemaExistsError.new name if exists?

      @client.backend do |b|
        b.create_search_schema name, content
      end
      
      @schema_data = nil

      true
    end

    private
    def schema_data
      return @schema_data if defined?(@schema_data) && @schema_data

      sd = nil

      begin
        sd = @client.backend do |b|
          b.get_search_schema name
        end
      rescue Riak::ProtobuffsFailedRequest => e
        return nil if e.not_found?
        raise e
      end
      
      return @schema_data = sd
    end
  end
end

