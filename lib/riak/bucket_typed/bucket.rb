require 'riak/bucket'

module Riak
  module BucketTyped
    class Bucket < Riak::Bucket
      attr_reader :type
      def initialize(client, name, type)
        @type = type

        super client, name
      end

      def new(key=nil)
        RObject.new self, key
      end
      end
    end
  end
end
