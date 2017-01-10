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
  def time_series_delete_operator
    TimeSeriesDeleteOperator.new(self)
  end

  class TimeSeriesDeleteOperator < Operator
    def delete(table_name, key_components, options = {})
      codec = TsCellCodec.new

      request_options = options.merge(table: table_name,
                                      key: codec.cells_for(key_components))

      request = TsDelReq.new request_options

      backend.protocol do |p|
        p.write :TsDelReq, request
        p.expect :TsDelResp, TsDelResp, empty_body_acceptable: true
      end
    end
  end
end
