require 'riak/search'
require 'riak/errors/search_error'

module Riak::Search
  # A schema is a Riak Search 2 concept that describes how to index documents.
  # They're implemented as a standard Solr XML schema.
  class Schema
    # @return [String] the name of the schema
    attr_reader :name

    # Initializes a schema object, that may or may not exist.
    #
    # @param [Riak::Client] client the client connected to the Riak cluster
    #   you wish to operate on
    # @param [String] name the name of the schema
    def initialize(client, name)
      @client = client
      @name = name
    end

    # @return [Boolean] does this schema exist on Riak?
    def exists?
      !!schema_data
    end

    # @return [String] the XML content of this schema
    def content
      schema_data.content
    end

    # @param [String] content the XML content of this schema
    # @raise [Riak::SearchError::SchemaExistsError] if a schema with the given
    #   name already exists
    def create!(content)
      fail Riak::SearchError::SchemaExistsError.new name if exists?

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

      @schema_data = sd
    end
  end
end
