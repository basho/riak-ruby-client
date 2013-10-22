module Riak
  module Crdt
    class Counter
      def initialize(bucket, key, bucket_type=DEFAULT_COUNTER_BUCKET_TYPE, options={})
        @bucket = bucket
        @key = key
        @bucket_type = bucket_type
        @options = options
      end

      def reload
        @result = client.backend do |be|
          be.fetch_crdt @bucket, @key, @bucket_type, @options
        end
      end

      def value
        return @value if defined? @value
        reload
        return @value = result.value unless result.value.nil?
        0
      end

      def increment(amount=1)
        counter_operation = Client::BeefcakeProtobuffsBackend::
          CounterOp.new increment: amount
        operation = Client::BeefcakeProtobuffsBackend::
          DtOp.new counter_op: counter_operation
        client.backend do |be|
          be.update_crdt @bucket, @key, @bucket_type, operation
        end
      end

      private
      def result
        return @result if defined? @result
        reload
        @result
      end
      
      def client
        @bucket.client
      end
    end
  end
end
