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

      alias :to_i :value

      def decrement(amount=1)
        increment -amount
      end
    end
  end
end
