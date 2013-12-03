module Riak
  module Crdt
    class Counter < Base
      def initialize(bucket, key, bucket_type=DEFAULT_COUNTER_BUCKET_TYPE, options={})
        super(bucket, key, bucket_type, options)
      end
      
      def value
        reload if dirty?
        return @value
      end

      def increment(amount=1, options={})
        operate operation(amount), options
      end

      def vivify(value)
        @value = value
      end
      
      alias :to_i :value

      def decrement(amount=1)
        increment -amount
      end
      private
      def operation(amount)
        Operation::Update.new.tap do |op|
          op.type = :counter
          op.value = amount
        end
      end
    end
  end
end
