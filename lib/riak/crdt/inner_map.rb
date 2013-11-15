module Riak
  module Crdt
    class InnerMap
      attr_reader :counters, :flags, :maps, :registers, :sets
      
      def initialize(parent, value)
        @parent = parent

        initialize_collections
      end

      def operate(inner_operation)
        wrapped_operation = Operation::Update.new.tap do |op|
          op.value = inner_operation
          op.type = :map
        end

        @parent.operate(wrapped_operation)
      end

      def self.delete
        Operation::Delete.new.tap do |op|
          op.type = :map
        end
      end

      private
      def initialize_collections
        @counters = TypedCollection.new Counter, self
        @flags = TypedCollection.new Flag, self
        @maps = TypedCollection.new InnerMap, self
        @registers = TypedCollection.new Register, self
        @sets = TypedCollection.new Set, self
      end
    end
  end
end
