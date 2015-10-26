module Riak::TimeSeries

  # Delete entries from Riak Time Series.
  class Deletion
    attr_accessor :keys
    attr_accessor :options
    
    attr_reader :client
    attr_reader :table_name

    def initialize(client, table_name)
      @client = client
      @table_name = table_name
      @options = Hash.new
    end

    def delete!
      client.backend do |be|
        be.time_series_delete_operator.delete(table_name,
                                              keys,
                                              options)
      end
      true
    end
  end
end
