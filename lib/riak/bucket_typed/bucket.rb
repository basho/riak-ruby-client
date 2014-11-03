require 'riak/bucket'
require 'riak/bucket_type'

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

      def get(key, options={  })
        super key, { type: type.name }.merge(options)
      end
      alias :[] :get
    end
  end
end
