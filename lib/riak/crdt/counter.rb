module Riak
  module Crdt
    class Counter < Base
      def initialize(bucket, key, bucket_type=DEFAULT_COUNTER_BUCKET_TYPE, options={})
        super(bucket, key, bucket_type, options)
      end
      
      def value
        return result.counter_value unless result.nil? || result.counter_value.nil?
        0
      end

      def increment(amount=1, options = {})
        counter_operation = backend_class::CounterOp.new increment: amount
        operation = backend_class::DtOp.new counter_op: counter_operation
        response = send_operation operation, options
        if response && response.counter_value
          # nastily put this back in the existing result 
          @result = response
        else
          @result = nil
        end
      end

      def decrement(amount=1)
        increment -amount
      end
    end
  end
end
