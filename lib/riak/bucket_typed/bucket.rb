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
      def get(key, options = {  })
        object = super key, o(options)
        object.bucket = self
        return object
      end
      alias :[] :get

      # Deletes a key from the bucket
      # @param [String] key the key to delete
      # @param [Hash] options quorum options
      # @option options [Fixnum] :rw - the read/write quorum for the
      #   delete
      # @option options [String] :vclock - the vector clock of the
      #   object being deleted
      def delete(key, options = {  })
        super key, o(options)
      end

      # Retrieves a list of keys in this bucket.
      # If a block is given, keys will be streamed through
      # the block (useful for large buckets). When streaming,
      # results of the operation will not be returned to the caller.
      # @yield [Array<String>] a list of keys from the current chunk
      # @return [Array<String>] Keys in this bucket
      # @note This operation has serious performance implications and
      #    should not be used in production applications.
      def keys(options = {  }, &block)
        super o(options), &block
      end

      # @return [String] a friendly representation of this bucket-typed bucket
      def inspect
        "#<Riak::BucketTyped::Bucket {#{ type.name }/#{ name }}>"
      end

      def props=(new_props)
        raise ArgumentError, t('hash_type', hash: new_props.inspect) unless new_props.is_a? Hash
        complete_props = props.merge new_props
        @client.set_bucket_props(self, complete_props, self.type.name)
      end

      def props
        @props ||= @client.get_bucket_props(self, type: self.type.name)
      end

      def clear_props
        @props = nil
        @client.clear_bucket_props(self, type: self.type.name)
      end

      # Pretty prints the bucket for `pp` or `pry`.
      def pretty_print(pp)
        pp.object_group self do
          pp.breakable
          pp.text "bucket_type="
          type.pretty_print(pp)
          pp.breakable
          pp.text "name=#{name}"
        end
      end

      # Queries a secondary index on the bucket-typed bucket.
      # @note This will only work if your Riak installation supports 2I.
      # @param [String] index the name of the index
      # @param [String,Integer,Range] query the value of the index, or a
      #   Range of values to query
      # @return [Array<String>] a list of keys that match the index
      #   query
      def get_index(index, query, options = {  })
        super index, query, o(options)
      end

      # Does this {BucketTyped::Bucket} have a non-default bucket type?
      # @return [Boolean] true if this bucket has a non-default type.
      def needs_type?
        return true unless type.default?
        return false
      end

      def ==(other)
        return false unless self.class == other.class
        return false unless self.type == other.type
        super
      end

      private
      # merge in the type name with options
      def o(options)
        { type: type.name }.merge options
      end
    end
  end
end
