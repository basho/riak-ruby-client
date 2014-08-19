module Riak
  module Crdt

    # A distributed map of multiple fields, such as counters, flags, registers,
    # sets, and, recursively, other maps, using the Riak 2 Data Types feature.
    #
    # Maps are complex, and the implementation is spread across many classes.
    # You're looking at the top-level {Map} class, but there are also others
    # that are also responsible for how maps work:
    #
    # * {InnerMap}: used for maps that live inside other maps
    # * {BatchMap}: proxies multiple operations into a single Riak update request
    # * {TypedCollection}: a collection of members of a single map, similar
    #   to a Ruby {Hash}
    # * {InnerFlag}: a boolean value inside a map
    # * {InnerRegister}: a {String} value inside a map
    # * {InnerCounter}: a {Riak::Crdt::Counter}, but inside a map
    # * {InnerSet}: a {Riak::Crdt::Set}, but inside a map
    # 
    class Map < Base
      attr_reader :counters, :flags, :maps, :registers, :sets
      
      # Create a map instance. If not provided, the default bucket type
      # from {Riak::Crdt} will be used.
      #
      # @param bucket [Bucket] the {Riak::Bucket} for this map
      # @param [String, nil] key The name of the map. A nil key makes
      #        Riak assign a key.
      # @param [String] bucket_type The optional bucket type for this map.
      #        The default is in `Crdt::Base::DEFAULT_BUCKET_TYPES[:map]`.
      # @param options [Hash]
      def initialize(bucket, key, bucket_type=nil, options={})
        super(bucket, key, bucket_type || DEFAULT_BUCKET_TYPES[:map], options)

        if key
          initialize_collections 
        else
          initialize_blank_collections
        end
      end

      # Maps are frequently updated in batches. Use this method to get a 
      # {BatchMap} to turn multiple operations into a single Riak update
      # request.
      #
      # @yieldparam batch_map [BatchMap] collects updates and other operations 
      def batch(*args)
        batch_map = BatchMap.new self

        yield batch_map

        write_operations batch_map.operations, *args
      end

      # This method *for internal use only* is used to collect oprations from
      # disparate sources to provide a user-friendly API.
      # 
      # @api private
      def operate(operation, *args)
        batch *args do |m|
          m.operate operation
        end
      end
      
      private
      def vivify(data)
        @counters = TypedCollection.new InnerCounter, self, data[:counters]
        @flags = TypedCollection.new InnerFlag, self, data[:flags]
        @maps = TypedCollection.new InnerMap, self, data[:maps]
        @registers = TypedCollection.new InnerRegister, self, data[:registers]
        @sets = TypedCollection.new InnerSet, self, data[:sets]
      end

      def initialize_collections(data={})
        reload if dirty?
      end

      def initialize_blank_collections
        vivify counters: {}, flags: {}, maps: {}, registers: {}, sets: {}
      end

      def write_operations(operations, *args)
        result = operator do |op|
          op.operate(bucket.name,
                     key,
                     bucket_type,
                     operations,
                     *args
                     )
        end

        @key ||= result.key

        # collections break dirty tracking
        reload
      end
    end
  end
end
