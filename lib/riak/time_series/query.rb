module Riak::TimeSeries

  # A query for Riak Time Series. Supports SQL for querying (data
  # manipulation language, or DML).
  class Query

    # @!attribute [rw] query_text
    # @return [String] the SQL query to run
    attr_accessor :query_text

    # Values to be interpolated into the query, support planned in Riak TS
    # 1.2
    attr_accessor :interpolations

    # @!attribute [r] client
    # @return [Riak::Client] the Riak client to use for the TS query
    attr_reader :client

    # #!attribute [r] results
    # @return [Riak::Client::BeefcakeProtobuffsBackend::TsQueryResp]
    #   backend-dependent results object
    attr_reader :results

    # Initialize a query object
    #
    # @param [Riak::Client] client the client connected to the riak cluster
    # @param [String] query_text the SQL query to run
    # @param interpolations planned for Riak TS 1.1
    def initialize(client, query_text, interpolations = {})
      @client = client
      @query_text = query_text
      @interpolations = interpolations
    end

    # Run the query against Riak TS, and store the results in the `results`
    # attribute
    def issue!
      @results = client.backend do |be|
        be.time_series_query_operator.query(query_text, interpolations)
      end
    end
  end
end
