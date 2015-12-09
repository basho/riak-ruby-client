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
