module Riak::TimeSeries
  class Submission
    attr_accessor :measurements
    attr_reader :client
    attr_reader :table_name

    def initialize(client, table_name)
      @client = client
      @table_name = table_name
    end

    def write!
      client.backend do |be|
        be.time_series_put_operator.put(table_name, measurements)
      end
    end
  end
end
