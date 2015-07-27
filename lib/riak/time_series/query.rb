module Riak::TimeSeries
  class Query
    attr_accessor :query_text
    attr_accessor :interpolations
    attr_reader :client
    attr_reader :results

    def initialize(client, query_text, interpolations = {})
      @client = client
      @query_text = query_text
      @interpolations = interpolations
    end

    def issue!
      @results = client.backend do |be|
        be.time_series_query_operator.query(query_text, interpolations)
      end
    end
  end
end
