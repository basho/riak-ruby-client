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


      private
    end
  end
end
