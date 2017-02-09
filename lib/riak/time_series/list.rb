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

require 'riak/errors/list_error'

module Riak::TimeSeries

  # A request to list keys in a Riak Time Series collection. Very expensive,
  # not recommended for use in production.
  class List
    include Riak::Util::Translation

    # @!attribute [r] table_name
    # @return [String] the table name to list keys in
    attr_reader :table_name

    # @!attribute [r] client
    # @return [Riak::Client] the Riak client to use for the list keys operation
    attr_reader :client

    # @!attribute [rw] timeout
    # @return [Integer] how many milliseconds Riak should wait for listing
    attr_accessor :timeout

    # @!attribute [r] results
    # @return [Riak::TimeSeries::Collection<Riak::TimeSeries::Row>] each key
    #   as a row in a collection; nil if keys were streamed to a block
    attr_reader :results

    # Initializes but does not issue the list keys operation
    #
    # @param [Riak::Client] client the Riak Client to list keys with
    # @param [String] table_name the table name to list keys in
    def initialize(client, table_name)
      @client = client
      @table_name = table_name
      @timeout = nil
    end

    # Issue the list keys request. Takes a block for streaming results, or
    # sets the #results read-only attribute iff no block is given.
    #
    # @yieldparam key [Riak::TimeSeries::Row] a listed key
    def issue!(&block)
      unless Riak.disable_list_exceptions
        msg = t('time_series.list_keys', :backtrace => caller.join("\n    "))
        raise Riak::ListError.new(msg)
      end

      options = { timeout: self.timeout }

      potential_results = nil

      client.backend do |be|
        op = be.time_series_list_operator(client.convert_timestamp)
        potential_results = op.list(table_name, block, options)
      end

      return @results = potential_results unless block_given?

      true
    end
  end
end
