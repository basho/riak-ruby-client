module Riak
  module Crdt

    # A distributed counter that supports incrementing and decrementing. This
    # `Counter` uses the Riak 2 Data Types feature. If you're interested in
    # Riak 1.4 Counters, see {Riak::Counter}.
    class Counter < Base

      # Create a counter instance. The bucket type is determined by the first of
      # these sources:
      #
      # 1. The `bucket_type` String argument
      # 2. A {BucketTyped::Bucket} as the `bucket` argument
      # 3. The `Crdt::Base::DEFAULT_BUCKET_TYPES[:counter]` entry
      #
      # @param [Bucket] bucket the {Riak::Bucket} for this counter
      # @param [String, nil] key The name of the counter. A nil key makes
      #        Riak assign a key.
      # @param [String] bucket_type The optional bucket type for this counter.
      #        The default is in `Crdt::Base::DEFAULT_BUCKET_TYPES[:counter]`.
      # @param [Hash] options
      def initialize(bucket, key, bucket_type=nil, options={})
        super(bucket, key, bucket_type || :counter, options)
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

      def pretty_print(pp)
        super pp do
          pp.comma_breakable
          pp.text "value=#{value}"
        end
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
