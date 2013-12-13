module Riak
  module Crdt
    class BatchMap
      attr_reader :counters, :flags, :maps, :registers, :sets
      
      def initialize(parent)
        @parent = parent
        @queue = []

        initialize_collections
      end

      def operate(operation)
        @queue << operation
      end

      def operations
        @queue.map do |q|
          Operation::Update.new.tap do |op|
            op.type = :map
            op.value = q
          end
        end
      end
      
      private
      def initialize_collections
        @counters = @parent.counters.reparent self
        @flags = @parent.flags.reparent self
        @maps = @parent.maps.reparent self
        @registers = @parent.registers.reparent self
        @sets = @parent.sets.reparent self
      end
    end
  end
end
