module Riak
  module Crdt
    class Counter < Base
      def initialize(bucket, key, bucket_type=DEFAULT_COUNTER_BUCKET_TYPE, options={})
        super(bucket, key, bucket_type, options)
      end
      
      def value
        return result.value.counter_value unless result.value.nil?
        0
      end

      def increment(amount=1)
        counter_operation = backend_class::CounterOp.new increment: amount
        operation = backend_class::DtOp.new counter_op: counter_operation
        backend.update_crdt @bucket, @key, @bucket_type, operation
        @result = nil
      end

      def decrement(amount=1)
        increment -amount
      end
    end
  end
end
