require_relative './ts_cell_codec'
require_relative './operator'

class Riak::Client::BeefcakeProtobuffsBackend
  def time_series_query_operator(convert_timestamp)
    TimeSeriesQueryOperator.new(self, convert_timestamp)
  end

  class TimeSeriesQueryOperator < Operator
    def initialize(backend, convert_timestamp)
      super(backend)
      @convert_timestamp = convert_timestamp
    end

    def query(base, interpolations = {  })
      interpolator = TsInterpolation.new base: base
      interpolator.interpolations = pairs_for interpolations

      request = TsQueryReq.new query: interpolator

      result = backend.protocol do |p|
        p.write :TsQueryReq, request
        p.expect :TsQueryResp, TsQueryResp, empty_body_acceptable: true
      end

      return [] if :empty == result

      codec = TsCellCodec.new(@convert_timestamp)

      collection = Riak::TimeSeries::Collection.
                   new(result.rows.map do |row|
                         Riak::TimeSeries::Row.new codec.scalars_for row.cells
                       end)

      collection.columns = result.columns

      collection
    end

    private
    def pairs_for(interpolations)
      interpolations.map do |key, value|
        RpbPair.new key: key.to_s, value: value.to_s
      end
    end
  end
end
