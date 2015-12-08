module Riak::TimeSeries
  class Submission

    # @!attributes [rw] measurements
    # @return [Array<Array<Object>>] measurements to write to Riak TS
    attr_accessor :measurements

    # @!attribute [r] client
    # @return [Riak::Client] the client to write submissions to
    attr_reader :client

    # @!attribute [r] table_name
    # @return [String] the table name to write submissions to
    attr_reader :table_name

    # Initializes the submission object with a client and table name
    #
    # @param [Riak::Client] client the client connected to the Riak TS cluster
    # @param [String] table_name the table name in the cluster
    def initialize(client, table_name)
      @client = client
      @table_name = table_name
    end

    # Write the submitted data to Riak.
    def write!
      client.backend do |be|
        be.time_series_put_operator.put(table_name, measurements)
      end
    end
  end
end
