module Riak::TimeSeries
  class Read
    attr_accessor :key
    attr_reader :client
    attr_reader :table_name

    def initialize(client, table_name)
      @client = client
      @table_name = table_name
    end

    def read!
      client.backend do |be|
        op = be.time_series_get_operator(client.convert_timestamp)
        op.get(table_name, key)
      end
    end
  end
end
