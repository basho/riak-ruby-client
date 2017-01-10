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
  class Submission

    # @!attributes [rw] measurements
    # @return [Array<Array<Object>>] measurements to write to Riak TS
    attr_accessor :measurements

    # @!attribute [r] client
    # @return [Riak::Client] the client to write submissions to
    attr_reader :client

    # @!attribute [r] table_name
    # @return [String] the table name to write submissions to
    attr_reader :table_name

    # Initializes the submission object with a client and table name
    #
    # @param [Riak::Client] client the client connected to the Riak TS cluster
    # @param [String] table_name the table name in the cluster
    def initialize(client, table_name)
      @client = client
      @table_name = table_name
    end

    # Write the submitted data to Riak.
    def write!
      client.backend do |be|
        be.time_series_put_operator.put(table_name, measurements)
      end
    end
  end
end
