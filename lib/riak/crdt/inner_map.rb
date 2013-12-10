module Riak
  module Crdt
    class InnerMap
      attr_reader :counters, :flags, :maps, :registers, :sets
      
      def initialize(parent, value={})
        @parent = parent
        @value = value.symbolize_keys

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
        @counters = TypedCollection.new InnerCounter, self, @value[:counters]
        @flags = TypedCollection.new Flag, self, @value[:flags]
        @maps = TypedCollection.new InnerMap, self, @value[:maps]
        @registers = TypedCollection.new Register, self, @value[:registers]
        @sets = TypedCollection.new InnerSet, self, @value[:sets]
      end
    end
  end
end
