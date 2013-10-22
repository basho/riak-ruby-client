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
        return @value = result.value.counter_value unless result.value.nil?
        0
      end

      def increment(amount=1)
        counter_operation = backend_class::CounterOp.new increment: amount
        operation = backend_class::DtOp.new counter_op: counter_operation
        backend.update_crdt @bucket, @key, @bucket_type, operation
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

      def backend
        client.backend{|be| be}
      end

      def backend_class
        backend.class
      end
    end
  end
end
