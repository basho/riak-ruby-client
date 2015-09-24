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
      serializer = TimeSeriesSerializer.new
      rows = serializer.rows_for measurements

      request = TsPutReq.new table: table_name, rows: rows

      backend.protocol do |p|
        p.write :TsPutReq, request
        p.expect :TsPutResp, TsPutResp, empty_body_acceptable: true
      end
    end
  end
end
