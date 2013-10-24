module Riak
  module Crdt
    class Set < Base
      def initialize(bucket, key, bucket_type=DEFAULT_SET_BUCKET_TYPE, options={})
        super(bucket, key, bucket_type, options)
      end

      def members
        return ::Set.new result.set_value unless result.nil? || result.set_value.nil?
        return ::Set.new
      end

      def include?(candidate)
        members.include?(candidate)
      end

      def add(*candidates)
        set_operate backend_class::SetOp.new adds: candidates
      end

      def remove(*candidates)
        set_operate backend_class::SetOp.new removes: candidates
      end

      private
      def set_operate(set_op)
        op = backend_class::DtOp.new set_op: set_op
        response = send_operation op
        if response && response.set_value
          @result = response
        else
          @result = nil
        end
      end
    end
  end
end
