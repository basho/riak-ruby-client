require 'riak/bucket'
require 'riak/bucket_type'

module Riak
  
  # Container module for subclasses of objects with bucket type data attached.
  # Currently only used for {BucketTyped::Bucket}.
  module BucketTyped
  
    # A bucket that has a {BucketType} attached to it. Normally created using
    # the {BucketType#bucket} method. Inherits most of its behavior from the
    # {Riak::Bucket} class.
    class Bucket < Riak::Bucket
      
      # @return [BucketType] the bucket type used with this bucket
      attr_reader :type

      # Create a bucket-typed bucket manually.
      # @param [Client] client the {Riak::Client} for this bucket
      # @param [String] name the name of this bucket
      # @param [BucketType,String] type the bucket type of this bucket
      def initialize(client, name, type)
        if type.is_a? String
          type = client.bucket_type type
        elsif !(type.is_a? BucketType)
          raise ArgumentError, t('argument_error.bucket_type', bucket_type: type)
        end

        @type = type

        super client, name
      end

      # Retrieve an object from within the bucket type and bucket.
      # @param [String] key the key of the object to retrieve
      # @param [Hash] options query parameters for the request
      # @option options [Fixnum] :r - the read quorum for the request - how many nodes should concur on the read
      # @return [Riak::RObject] the object
      # @raise [FailedRequest] if the object is not found or some other error occurs
      def get(key, options={  })
        super key, { type: type.name }.merge(options)
      end
      alias :[] :get

      # Deletes a key from the bucket
      # @param [String] key the key to delete
      # @param [Hash] options quorum options
      # @option options [Fixnum] :rw - the read/write quorum for the
      #   delete
      # @option options [String] :vclock - the vector clock of the
      #   object being deleted
      def delete(key, options={  })
        super key, { type: type.name }.merge(options)
      end
    end
  end
end
