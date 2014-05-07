module Riak
  module Crdt

    # Basic and shared code used by the top-level CRDTs. In particular, dirty-
    # tracking, loading, and operating is implemented by this class, and
    # the {Riak::Crdt::Set}, {Riak::Crdt::Counter}, and {Riak::Crdt::Map}
    # classes implement everything else.
    #
    # @api private
    class Base
      include Util::Translation
      attr_reader :bucket
      attr_reader :bucket_type

      # Returns the key of this CRDT. Extremely useful when using a 
      # Riak-assigned key.
      attr_reader :key

      def initialize(bucket, key, bucket_type, options={})
        raise ArgumentError, t("bucket_type", bucket: bucket.inspect) unless bucket.is_a? Bucket

        unless key.is_a? String or key.nil?
          raise ArgumentError, t("string_type", string: key.inspect)
        end

        @bucket = bucket
        @key = key
        @bucket_type = bucket_type
        @options = options

        @dirty = true
      end

      def dirty?
        @dirty
      end
      
      # Force a reload of this structure from Riak.
      def reload
        loader do |l|
          vivify l.load @bucket, @key, @bucket_type
          @context = l.context
        end
        @dirty = false
      end
      
      private
      def client
        @bucket.client
      end

      def backend(&blk)
        client.backend &blk
      end

      def loader
        backend do |be|
          yield be.crdt_loader
        end
      end
      
      def operator
        backend do |be|
          yield be.crdt_operator
        end
      end

      def operate(*args)
        operator do |op|
          response = op.operate(bucket.name,
                                key,
                                bucket_type,
                                *args
                                )

          @key = response.key if response.key
        end

        @dirty = true
      end
    end
  end
end
