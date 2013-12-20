module Riak
  module Crdt
    class Map < Base
      attr_reader :counters, :flags, :maps, :registers, :sets
      
      def initialize(bucket, key, bucket_type=nil, options={})
        super(bucket, key, bucket_type || DEFAULT_BUCKET_TYPES[:map], options)

        initialize_collections
      end

      def batch(*args)
        batch_map = BatchMap.new self

        yield batch_map

        write_operations batch_map.operations, *args
      end

      def operate(operation, *args)
        batch *args do |m|
          m.operate operation
        end
      end

      def vivify(data)
        @counters = TypedCollection.new InnerCounter, self, data[:counters]
        @flags = TypedCollection.new Flag, self, data[:flags]
        @maps = TypedCollection.new InnerMap, self, data[:maps]
        @registers = TypedCollection.new Register, self, data[:registers]
        @sets = TypedCollection.new InnerSet, self, data[:sets]
      end
      
      private
      def initialize_collections(data={})
        reload if dirty?
      end

      def write_operations(operations, *args)
        op = operator
        op.operate(bucket.name,
                   key,
                   bucket_type,
                   operations,
                   *args
                   )

        # collections break dirty tracking
        reload
      end
    end
  end
end
