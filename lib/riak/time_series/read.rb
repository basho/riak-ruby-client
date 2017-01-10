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
  class Read
    attr_accessor :key
    attr_reader :client
    attr_reader :table_name

    def initialize(client, table_name)
      @client = client
      @table_name = table_name
    end

    def read!
      client.backend do |be|
        op = be.time_series_get_operator(client.convert_timestamp)
        op.get(table_name, key)
      end
    end
  end
end
