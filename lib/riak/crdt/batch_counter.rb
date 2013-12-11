module Riak
  module Crdt
    class BatchCounter
      attr_reader :accumulator
      
      def initialize
        @accumulator = 0
      end
      
      def increment(amount=1)
        @accumulator += amount
      end
      
      def decrement(amount=1)
        increment -amount
      end
    end
  end
end
