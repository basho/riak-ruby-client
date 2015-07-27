class Riak::Client::BeefcakeProtobuffsBackend
  def time_series_put_operator
    TimeSeriesPutOperator.new(self)
  end

  class TimeSeriesPutOperator
    attr_reader :backend

    def initialize(backend)
      @backend = backend
    end

    def put(table_name, measurements)
      rows = rows_for measurements

      request = TsPutReq.new table: table_name, rows: rows

      response = backend.protocol do |p|
        p.write :TsPutReq, request
        p.expect :TsPutResp, TsPutResp
      end
    end

    private
    def rows_for(measurements)
      measurements.map do |measurement|
        # expect a measurement to be mappable
        TsRow.new(cells: measurement.map do |measure|
          cell_for measure
        end)
      end
    end

    def cell_for(measure)
      TsCell.new case measure
                 when String
                   { binary_value: measure }
                 when Integer
                   { integer_value: measure }
                 when Numeric
                   { numeric_value: measure.to_s }
                 when Time
                   { timestamp_value: measure.to_i }
                 when TrueClass, FalseClass
                   { boolean_value: measure }
                 end
    end
  end
end
