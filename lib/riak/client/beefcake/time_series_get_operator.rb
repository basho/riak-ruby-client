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
