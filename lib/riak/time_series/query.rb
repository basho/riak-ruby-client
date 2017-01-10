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

module Riak::TimeSeries

  # A query for Riak Time Series. Supports SQL for querying (data
  # manipulation language, or DML).
  class Query

    # @!attribute [rw] query_text
    # @return [String] the SQL query to run
    attr_accessor :query_text

    # Values to be interpolated into the query, support planned in Riak TS
    # 1.2
    attr_accessor :interpolations

    # @!attribute [r] client
    # @return [Riak::Client] the Riak client to use for the TS query
    attr_reader :client

    # #!attribute [r] results
    # @return [Riak::Client::BeefcakeProtobuffsBackend::TsQueryResp]
    #   backend-dependent results object
    attr_reader :results

    # Initialize a query object
    #
    # @param [Riak::Client] client the client connected to the riak cluster
    # @param [String] query_text the SQL query to run
    # @param interpolations planned for Riak TS 1.1
    def initialize(client, query_text, interpolations = {})
      @client = client
      @query_text = query_text
      @interpolations = interpolations
    end

    # Run the query against Riak TS, and store the results in the `results`
    # attribute
    def issue!
      @results = client.backend do |be|
        op = be.time_series_query_operator(client.convert_timestamp)
        op.query(query_text, interpolations)
      end
    end
  end
end
