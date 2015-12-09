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
