class Riak::Client::BeefcakeProtobuffsBackend
  def time_series_query_operator
    TimeSeriesQueryOperator.new(self)
  end

  class TimeSeriesQueryOperator
    attr_reader :backend

    def initialize(backend)
      @backend = backend
    end

    def query(base, interpolations={  })
      interpolator = TsInterpolation.new base: base
      interpolator.interpolations = pairs_for interpolations

      request = TsQueryReq.new query: interpolator

      response = backend.protocol do |p|
        p.write :TsQueryReq, request
        p.expect :TsQueryResp, TsQueryResp
      end
    end

    private
    def pairs_for(interpolations)
      interpolations.map do |key, value|
        RpbPair.new key: key.to_s, value: value.to_s
      end
    end
  end
end
