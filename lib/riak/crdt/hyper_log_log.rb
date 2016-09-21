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

      # Yields a `BatchSet` to proxy multiple set operations into a single
      # Riak update. The `BatchSet` has the same methods as this
      # {Riak::Crdt::HyperLogLog}.
      #
      # @yieldparam batch_set [BatchSet] collects set operations
      def vivify(value)
        value.each(&:freeze)
        @members = ::Set.new(value)
        @members.freeze
      end

      def batch
        batcher = BatchSet.new self

        yield batcher

        operate batcher.operations
      end

      # Gets the current set members from Riak if necessary, and return the
      # stdlib `::HyperLogLog` of them.
      #
      # @return [::HyperLogLog] a Ruby standard library {::HyperLogLog} of the members
      #                 of this {Riak::Crdt::HyperLogLog}
      def members
        reload if dirty?
        @members
      end

      alias :value :members

      # Cast this {Riak::Crdt::HyperLogLog} to a Ruby {Array}.
      #
      # @return [Array] array of set members
      def to_a
        members.to_a
      end

      # Check to see if this structure has any members.
      #
      # @return [Boolean] if the structure is empty
      def empty?
        members.empty?
      end

      # Check to see if a given string is present in this data structure.
      #
      # @param [String] candidate string to check for inclusion in this structure
      # @return [Boolean] if the structure includes
      def include?(candidate)
        members.any? { |m| equal_bytes?(m, candidate) }
      end

      # Add a {String} to the {Riak::Crdt::HyperLogLog}
      #
      # @param [String] element the element to add to the set
      # @param [Hash] options
      def add(element, options = {})
        operate operation(:add, element), options
      end

      # Remove a {String} from the {Riak::Crdt::HyperLogLog}
      #
      # @param [String] element to remove from the set
      # @param [Hash] options
      def remove(element, options = {})
        raise CrdtError::SetRemovalWithoutContextError unless context?
        operate operation(:remove, element), options
      end

      alias :delete :remove

      def pretty_print(pp)
        super pp do
          pp.comma_breakable
          pp.pp to_a
        end
      end

      private
      def vivify(value)
        @members = value
      end

      def operation(direction, element)
        Operation::Update.new.tap do |op|
          op.type = :hyper_log_log
          op.value = { direction => element }
        end
      end

      class BatchHyperLogLog
        def initialize(base)
          @base = base
          @adds = ::Set.new
          @removes = ::Set.new
        end

        def add(element)
          @adds.add element
        end

        def remove(element)
          raise CrdtError::SetRemovalWithoutContextError.new unless context?
          @removes.add element
        end

        alias :delete :remove

        def include?(element)
          members.include? element
        end

        def empty?
          members.empty?
        end

        def context?
          @base.context?
        end

        def to_a
          members.to_a
        end

        def members
          (@base + @adds).subtract @removes
        end

        alias :value :members

        def operations
          Operation::Update.new.tap do |op|
            op.type = :hyper_log_log
            op.value = {add: @adds.to_a, remove: @removes.to_a}
          end
        end
      end
    end
  end
end
