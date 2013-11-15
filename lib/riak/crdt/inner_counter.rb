module Riak
  module Crdt
    class InnerCounter
      attr_accessor :name

      attr_reader :value
      alias :to_i :value
        
      def initialize(parent, value)
        @parent = parent
        @value = value
      end

      def increment(amount = 1)
        @parent.increment name, amount
      end

      def decrement(amount = 1)
        increment -amount
      end
    end
  end
end
