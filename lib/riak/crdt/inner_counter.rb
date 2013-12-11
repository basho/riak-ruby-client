module Riak
  module Crdt
    class InnerCounter
      attr_accessor :name

      attr_reader :value
      alias :to_i :value
        
      def initialize(parent, value=0)
        @parent = parent
        @value = value
      end

      def increment(amount = 1)
        @parent.increment name, amount
      end

      def decrement(amount = 1)
        increment -amount
      end

      def batch
        batcher = BatchCounter.new

        yield batcher

        increment batcher.accumulator
      end
      
      def self.update(increment)
        Operation::Update.new.tap do |op|
          op.value = increment
          op.type = :counter
        end
      end
    end
  end
end
