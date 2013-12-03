module Riak
  module Crdt
    class Base
      attr_reader :bucket, :key, :bucket_type
      
      def initialize(bucket, key, bucket_type, options={})
        @bucket = bucket
        @key = key
        @bucket_type = bucket_type
        @options = options
      end
      
      private
      def result
        return @result if @result
        reload
        @result
      end

      def reload
        l = loader
        vivify l.load @bucket, @key, @bucket_type
        @context = l.context
      end
      
      def client
        @bucket.client
      end

      def backend
        client.backend{|be| be}
      end

      def loader
        backend.crdt_loader
      end
    end
  end
end
