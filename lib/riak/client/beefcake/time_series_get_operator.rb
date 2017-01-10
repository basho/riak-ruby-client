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
  def time_series_get_operator(convert_timestamp)
    TimeSeriesGetOperator.new(self, convert_timestamp)
  end

  class TimeSeriesGetOperator < Operator
    def initialize(backend, convert_timestamp)
      super(backend)
      @convert_timestamp = convert_timestamp
    end

    def get(table_name, key_components, options = {})
      codec = TsCellCodec.new(@convert_timestamp)

      request_options = options.merge(table: table_name,
                                      key: codec.cells_for(key_components))

      request = TsGetReq.new request_options

      result = begin
        backend.protocol do |p|
          p.write :TsGetReq, request
          result = p.expect :TsGetResp, TsGetResp, empty_body_acceptable: true
        end
      rescue Riak::ProtobuffsErrorResponse => e
        raise unless e.code == 10
        return nil
      end

      return nil if result == :empty

      Riak::TimeSeries::Collection.new(result.rows.map do |row|
        Riak::TimeSeries::Row.new codec.scalars_for row.cells
      end.to_a)
    end
  end
end
