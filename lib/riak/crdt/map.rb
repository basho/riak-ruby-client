module Riak
  module Crdt
    class Map < Base
      def initialize(bucket, key, bucket_type=DEFAULT_MAP_BUCKET_TYPE, options={})
        super(bucket, key, bucket_type, options)
        @counters = Hash.new
        @flags = Hash.new
        @maps = Hash.new
        @registers = Hash.new
        @sets = Hash.new
      end

      def registers
        @registers
      end

      private
      def load_entries
        result.value.map_value.each do |e|
          f = e.field
          pp e
          pp f
        end
      end
    end
  end
end
