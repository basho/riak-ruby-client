module Riak
  module Crdt
    class InnerMap
      attr_reader :counters, :flags, :maps, :registers, :sets
      
      def initialize(parent, value)
        @parent = parent

        initialize_collections
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
