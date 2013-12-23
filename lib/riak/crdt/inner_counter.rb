module Riak
  module Crdt
    # The {InnerCounter} lives inside a {Map}, or an {InnerMap} inside of a 
    # {Map}, and is accessed through a {TypedCollection}.
    #
    # Much like the {Riak::Crdt::Counter}, it provides an integer value that can
    # be incremented and decremented.
    class InnerCounter
      # The name of this counter inside a map.
      #
      # @api private
      attr_accessor :name

      # The value of this counter.
      #
      # @return [Integer] counter value
      attr_reader :value
      alias :to_i :value
        
      # @api private
      def initialize(parent, value=0)
        @parent = parent
        @value = value
      end

      # Increment the counter.
      #
      # @param [Integer] amount How much to increment the counter by.
      def increment(amount = 1)
        @parent.increment name, amount
      end

      # Decrement the counter. Opposite of increment.
      #
      # @param [Integer] amount How much to decrement from the counter.
      def decrement(amount = 1)
        increment -amount
      end

      # Perform multiple increments against this counter, and collapse
      # them into a single operation.
      #
      # @yieldparam [BatchCounter] batch_counter actually collects the
      #                            operations.
      def batch
        batcher = BatchCounter.new

        yield batcher

        increment batcher.accumulator
      end
      
      # @api private
      def self.update(increment)
        Operation::Update.new.tap do |op|
          op.value = increment
          op.type = :counter
        end
      end
    end
  end
end
