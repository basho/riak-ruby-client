module Riak
  module Crdt
    class Base
      include Util::Translation
      attr_reader :bucket, :key, :bucket_type
      
      def initialize(bucket, key, bucket_type, options={})
        raise ArgumentError, t("bucket_type", bucket: bucket.inspect) unless bucket.is_a? Bucket
        raise ArgumentError, t("string_type", string: key.inspect) unless key.is_a? String
        @bucket = bucket
        @key = key
        @bucket_type = bucket_type
        @options = options

        @dirty = true
      end

      def dirty?
        @dirty
      end
      
      private

      def reload
        l = loader
        vivify l.load @bucket, @key, @bucket_type
        @context = l.context
        @dirty = false
      end
      
      def client
        @bucket.client
      end

      def backend
        pp @bucket
        pp client
        client.backend{|be| be}
      end

      def loader
        backend.crdt_loader
      end

      def operate(*args)
        op = operator
        op.operate(bucket.name,
                   key,
                   bucket_type,
                   *args
                   )
        @dirty = true
      end
      
      def operator
        backend.crdt_operator
      end
    end
  end
end
