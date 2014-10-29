require 'riak/robject'

module Riak
  module BucketTyped
    class RObject < Riak::RObject
      attr_reader :type

      def initialize(typed_bucket, key=nil)
        @type = typed_bucket.type
        super typed_bucket, key
      end
    end
  end
end
