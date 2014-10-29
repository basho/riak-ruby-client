require 'riak/bucket'
require 'riak/bucket_typed/robject'

module Riak
  module BucketTyped
    class Bucket < Riak::Bucket
      attr_reader :type
      def initialize(client, name, type)
        @type = type

        super client, name
      end

      def new(key=nil)
        BucketTyped::RObject.new self, key
      end
    end
  end
end
