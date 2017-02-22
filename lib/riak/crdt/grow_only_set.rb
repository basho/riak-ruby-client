# Copyright 2010-present Basho Technologies, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'riak/util/string'

module Riak
  module Crdt

    # A distributed grow-only set containing strings, using the Riak 2 Data Types feature.
    #
    # Uses the Ruby standard library `::Set` frequently, so the full class names will
    # be used frequently.
    class GrowOnlySet < Base
      include Util::String

      # Create a grow-only set instance. The bucket type is determined by the first of
      # these sources:
      #
      # 1. The `bucket_type` String argument
      # 2. A {BucketTyped::Bucket} as the `bucket` argument
      # 3. The `Crdt::Base::DEFAULT_BUCKET_TYPES[:gset]` entry
      #
      # @param bucket [Bucket] the {Riak::Bucket} for this grow-only set
      # @param [String, nil] key The name of the grow-only set. A nil key makes
      #        Riak assign a key.
      # @param [String] bucket_type The optional bucket type for this grow-only set.
      # @param options [Hash]
      def initialize(bucket, key, bucket_type = nil, options = {})
        super(bucket, key, bucket_type || :gset, options)
      end

      # Yields a `BatchGrowOnlySet` to proxy multiple add operations into a single
      # Riak update. The `BatchGrowOnlySet` has the same methods as this
      # {Riak::Crdt::GrowOnlySet}.
      #
      # @yieldparam batch_grow_only_set [BatchGrowOnlySet] collects add operations
      def vivify(value)
        value.each(&:freeze)
        @members = ::Set.new(value)
        @members.freeze
      end

      def batch
        batcher = BatchGrowOnlySet.new self

        yield batcher

        operate batcher.operations
      end

      # Gets the current set members from Riak if necessary, and return the
      # stdlib `::Set` of them.
      #
      # @return [::Set] a Ruby standard library {::Set} of the members
      #                 of this {Riak::Crdt::GrowOnlySet}
      def members
        reload if dirty?
        @members
      end

      alias :value :members

      # Cast this {Riak::Crdt::GrowOnlySet} to a Ruby {Array}.
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

      # Add a {String} to the {Riak::Crdt::GrowOnlySet}
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
      def operation(direction, element)
        Operation::Update.new.tap do |op|
          op.type = :gset
          op.value = { direction => element }
        end
      end

      class BatchGrowOnlySet
        def initialize(base)
          @base = base
          @adds = ::Set.new
        end

        def add(element)
          @adds.add element
        end

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
          @base + @adds
        end

        alias :value :members

        def operations
          Operation::Update.new.tap do |op|
            op.type = :gset
            op.value = {add: @adds.to_a}
          end
        end
      end
    end
  end
end
