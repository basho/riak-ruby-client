# Copyright 2010-present Basho Technologies, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'riak/search'
require 'riak/errors/search_error'

module Riak::Search
  # A {Riak::Search::Index} is how Solr finds documents in Riak Search 2. A
  # bucket or bucket type property must be configured to use the index in order
  # for new and updated documents to be indexed and searchable.
  class Index
    # @!attribute [r] name
    # @return [String] the name of the index
    attr_reader :name

    # @!attribute [r] client
    # @return [Riak::Client] the client to operate on the index with
    attr_reader :client

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
    def create!(schema = nil, n_val = nil, timeout = nil)
      raise Riak::SearchError::IndexExistsError.new name if exists?

      @client.backend do |b|
        b.create_search_index name, schema, n_val, timeout
      end

      @index_data = nil

      true
    end

    # Create a {Riak::Search::Query} using this index and client
    #
    # @param [String] term the query term
    # @param [Hash] options a hash of options to set attributes on the query
    # @return [Riak::Search::Query] a query using this index
    def query(term, options = {  })
      Riak::Search::Query.new(@client, self, term, options)
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
