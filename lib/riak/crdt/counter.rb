module Riak
  module Crdt

    # A distributed counter that supports incrementing and decrementing. This
    # `Counter` uses the Riak 2 Data Types feature. If you're interested in
    # Riak 1.4 Counters, see {Riak::Counter}.
    class Counter < Base

      # Create a counter instance. If not provided, the default bucket type
      # from {Riak::Crdt} will be used.
      #
      # @param [Bucket] bucket the {Riak::Bucket} for this counter
      # @param [String] key the name of the counter
      # @param [String] bucket_type the optional bucket type for this counter
      # @param [Hash] options
      def initialize(bucket, key, bucket_type=nil, options={})
        super(bucket, key, bucket_type || DEFAULT_BUCKET_TYPES[:counter], options)
      end
      
      # The current value of the counter; hits the server if the value has
      # not been fetched or if the counter has been incremented.
      def value
        reload if dirty?
        return @value
      end

      # Increment the counter.
      #
      # @param [Integer] amount
      # @param [Hash] options
      def increment(amount=1, options={})
        operate operation(amount), options
      end

      # Yields a {BatchCounter} to turn multiple increments into a single
      # Riak hit.
      #
      # @yieldparam [BatchCounter] batch_counter collects multiple increments
      def batch
        batcher = BatchCounter.new

        yield batcher
        
        increment batcher.accumulator
      end
      
      alias :to_i :value

      # Decrement the counter.
      #
      # @param [Integer] amount
      def decrement(amount=1)
        increment -amount
      end
      
      private
      def vivify(value)
        @value = value
      end

      def operation(amount)
        Operation::Update.new.tap do |op|
          op.type = :counter
          op.value = amount
        end
      end
    end
  end
end
