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
  def time_series_put_operator
    TimeSeriesPutOperator.new(self)
  end

  class TimeSeriesPutOperator < Operator
    def put(table_name, measurements)
      rows = rows_for measurements

      request = TsPutReq.new table: table_name, rows: rows

      backend.protocol do |p|
        p.write :TsPutReq, request
        p.expect :TsPutResp, TsPutResp, empty_body_acceptable: true
      end
    end

    private
    def rows_for(measurements)
      codec = TsCellCodec.new
      measurements.map do |measurement|
        # expect a measurement to be mappable
        TsRow.new(cells: measurement.map do |measure|
          codec.cell_for measure
        end)
      end
    end
  end
end
