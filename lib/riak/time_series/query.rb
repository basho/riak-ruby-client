module Riak::TimeSeries

  # A query against Riak Time Series. Supports SQL for both querying (data
  # manipulation language, or DDL) and creating collections (data definition
  # language, or DDL).
  class Query

    # The text of the query
    attr_accessor :query_text

    # Values to be interpolated into the query, not supported as of
    # July 29, 2015.
    attr_accessor :interpolations

    attr_reader :client

    # some kind of results object, currently backend-dependent
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
