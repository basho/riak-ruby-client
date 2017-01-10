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

require_relative './ts_cell_codec'
require_relative './operator'

class Riak::Client::BeefcakeProtobuffsBackend
  def time_series_list_operator(convert_timestamp)
    TimeSeriesListOperator.new(self, convert_timestamp)
  end

  class TimeSeriesListOperator < Operator
    def initialize(backend, convert_timestamp)
      super(backend)
      @convert_timestamp = convert_timestamp
    end

    def list(table_name, block, options = {  })
      request = TsListKeysReq.new options.merge(table: table_name)

      return streaming_list_keys(request, &block) unless block.nil?

      Riak::TimeSeries::Collection.new.tap do |key_buffer|
        streaming_list_keys(request) do |key_row|
          key_buffer << key_row
        end
      end
    end

    private

    def streaming_list_keys(request)
      backend.protocol do |p|
        p.write :TsListKeysReq, request

        codec = TsCellCodec.new(@convert_timestamp)

        while resp = p.expect(:TsListKeysResp, TsListKeysResp)
          break if resp.done
          resp.keys.each do |row|
            key_fields = codec.scalars_for row.cells
            yield key_fields
          end
        end
      end

      true
    end
  end
end
