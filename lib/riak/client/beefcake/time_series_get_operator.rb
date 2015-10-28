require_relative './ts_cell_codec'
require_relative './operator'

class Riak::Client::BeefcakeProtobuffsBackend
  def time_series_get_operator
    TimeSeriesGetOperator.new(self)
  end

  class TimeSeriesGetOperator < Operator
    def get(table_name, key_components, options = {})
      codec = TsCellCodec.new

      request_options = options.merge(table: table_name,
                                      key: codec.cells_for(key_components))

      request = TsGetReq.new request_options
pp request
      backend.protocol do |p|
        p.write :TsGetReq, request
        p.expect :TsGetResp, TsGetResp
      end
    end
  end
end
