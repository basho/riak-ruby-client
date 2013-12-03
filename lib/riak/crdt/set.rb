module Riak
  module Crdt
    class Set < Base
      
      def initialize(bucket, key, bucket_type=DEFAULT_SET_BUCKET_TYPE, options={})
        super(bucket, key, bucket_type, options)
      end

      def vivify(value)
        @members = value
      end

      def members
        reload if dirty?
        @members
      end
      
      def include?(candidate)
        members.include?(candidate)
      end

      def add(element, options={})
        operate operation(:add, element), options
      end

      def remove(element, options={})
        operate operation(:remove, element), options
      end
      
      private
      def operation(direction, element)
        Operation::Update.new.tap do |op|
          op.type = :set
          op.value = { direction => element }
        end
      end
    end
  end
end
