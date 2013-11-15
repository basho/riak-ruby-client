module Riak
  module Crdt
    class Map < Base
      attr_reader :counters, :flags, :maps, :registers, :sets
      
      def initialize(bucket, key, bucket_type=DEFAULT_MAP_BUCKET_TYPE, options={})
        super(bucket, key, bucket_type, options)

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
