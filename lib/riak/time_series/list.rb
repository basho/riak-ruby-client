module Riak::TimeSeries

  # A request to list keys in a Riak Time Series collection. Very expensive,
  # not recommended for use in production.
  class List
    include Riak::Util::Translation

    # @!attribute [r] table_name
    # @return [String] the table name to list keys in
    attr_reader :table_name

    # @!attribute [r] client
    # @return [Riak::Client] the Riak client to use for the list keys operation
    attr_reader :client

    # @!attribute [rw] timeout
    # @return [Integer] how many milliseconds Riak should wait for listing
    attr_accessor :timeout

    # @!attribute [r] results
    # @return [Riak::TimeSeries::Collection<Riak::TimeSeries::Row>] each key
    #   as a row in a collection; nil if keys were streamed to a block
    attr_reader :results

    # Initializes but does not issue the list keys operation
    #
    # @param [Riak::Client] client the Riak Client to list keys with
    # @param [String] table_name the table name to list keys in
    def initialize(client, table_name)
      @client = client
      @table_name = table_name
      @timeout = nil
    end

    # Issue the list keys request. Takes a block for streaming results, or
    # sets the #results read-only attribute iff no block is given.
    #
    # @yieldparam key [Riak::TimeSeries::Row] a listed key
    def issue!(&block)
      list_keys_warning(caller)

      options = { timeout: self.timeout }

      client.backend do |be|
        be.time_series_list_operator.list(table_name,
                                          block,
                                          options)
      end
    end

    private
    def list_keys_warning(bound_caller)
      return if Riak.disable_list_keys_warnings

      backtrace = bound_caller.join("\n    ")

      warn(t('time_series.list_keys'), backtrace: backtrace)
    end
  end
end
