require 'riak/search'
require 'riak/errors/search_error'

module Riak::Search
  class Index
    # @return [String] the name of the index
    attr_reader :name

    # Initializes an index object, that may or may not exist.
    #
    # @param [Riak::Client] client the client connected to the Riak cluster
    #   you wish to operate on
    # @param [String] name the name of the index
    def initialize(client, name)
      @client = client
      @name = name
    end

    # @return [Boolean] does this index exist on Riak?
    def exists?
      !!index_data
    end

    # @return [Integer] N-value/replication parameter of this index
    def n_val
      index_data[:n_val]
    end

    # @return [String] schema name of this index
    def schema
      index_data[:schema]
    end

    # Attempt to create this index
    #
    # @raise [Riak::SearchError::IndexExistsError] if an index with the given 
    #   name already exists
    def create!(schema = nil, n_val = nil)
      raise Riak::SearchError::IndexExistsError.new name if exists?

      @client.backend do |b|
        b.create_search_index name, schema, n_val
      end

      @index_data = nil

      true
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
