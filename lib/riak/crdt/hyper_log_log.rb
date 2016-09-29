require 'riak/util/string'

module Riak
  module Crdt

    # A distributed set containing strings, using the Riak 2 Data Types feature and Hyper Log Log algorithm
    class HyperLogLog < Base
      include Util::String

      # Create a set instance. The bucket type is determined by the first of
      # these sources:
      #
      # 1. The `bucket_type` String argument
      # 2. A {BucketTyped::Bucket} as the `bucket` argument
      # 3. The `Crdt::Base::DEFAULT_BUCKET_TYPES[:set]` entry
      #
      # @param bucket [Bucket] the {Riak::Bucket} for this set
      # @param [String, nil] key The name of the set. A nil key makes
      #        Riak assign a key.
      # @param [String] bucket_type The optional bucket type for this set.
      # @param options [Hash]
      def initialize(bucket, key, bucket_type = nil, options = {})
        super(bucket, key, bucket_type || :hyper_log_log, options)
      end

      # Gets the current HLL value from Riak
      #
      # @return [Integer]
      def value
        reload if dirty?
        @value
      end

      # Gets the current set members from Riak if necessary, and return the
      # stdlib `::Set` of them.
      #
      # @return [::Set] a Ruby standard library {::Set} of the members
      #                 of this {Riak::Crdt::Set}
      def members
        @members
      end

      # Add a {String} to the {Riak::Crdt::HyperLogLog}
      #
      # @param [String] element the element to add to the set
      # @param [Hash] options
      def add(element, options = {})
        operate operation(:add, element), options
      end

      def pretty_print(pp)
        super pp do
          pp.comma_breakable
          pp.pp to_a
        end
      end

      private
      def vivify(value)
        @value = value
      end

      def operation(direction, element)
        Operation::Update.new.tap do |op|
          op.type = :hyper_log_log
          op.value = { direction => element }
        end
      end
    end
  end
end
