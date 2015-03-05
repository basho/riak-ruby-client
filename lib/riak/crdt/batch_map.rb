module Riak
  module Crdt
    # A map that queues up its operations for the parent {Map} to send to
    # Riak all at once.
    class BatchMap
      attr_reader :counters, :flags, :maps, :registers, :sets

      # @api private
      def initialize(parent)
        @parent = parent
        @queue = []

        initialize_collections
      end

      # @api private
      def operate(operation)
        @queue << operation
      end

      # @api private
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
