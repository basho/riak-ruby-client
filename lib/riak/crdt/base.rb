module Riak
  module Crdt
    class Base
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
      
      def client
        @bucket.client
      end

      def backend
        client.backend{|be| be}
      end
    end
  end
end
