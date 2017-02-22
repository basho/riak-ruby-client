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

    # A distributed set containing strings, using the Riak 2 Data Types feature.
    #
    # Uses the Ruby standard library `::Set` frequently, so the full class names will
    # be used frequently.
    class Set < GrowOnlySet
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
        super(bucket, key, bucket_type || :set, options)
      end

      # Yields a `BatchSet` to proxy multiple set operations into a single
      # Riak update. The `BatchSet` has the same methods as this
      # {Riak::Crdt::Set}.
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

      # Cast this {Riak::Crdt::Set} to a Ruby {Array}.
      #
      # @return [Array] array of set members
      def to_a
        super.to_a
      end

      # Add a {String} to the {Riak::Crdt::Set}
      #
      # @param [String] element the element to add to the set
      # @param [Hash] options
      def add(element, options = {})
        operate operation(:add, element), options
      end

      # Remove a {String} from the {Riak::Crdt::Set}
      #
      # @param [String] element to remove from the set
      # @param [Hash] options
      def remove(element, options = {})
        raise CrdtError::SetRemovalWithoutContextError unless context?
        operate operation(:remove, element), options
      end

      alias :delete :remove

      private
      def operation(direction, element)
        Operation::Update.new.tap do |op|
          op.type = :set
          op.value = { direction => element }
        end
      end

      class BatchSet < GrowOnlySet::BatchGrowOnlySet
        def initialize(base)
          super(base)
          @removes = ::Set.new
        end

        def remove(element)
          raise CrdtError::SetRemovalWithoutContextError.new unless context?
          @removes.add element
        end

        alias :delete :remove

        def members
          (@base + @adds).subtract @removes
        end

        alias :value :members

        def operations
          Operation::Update.new.tap do |op|
            op.type = :set
            op.value = {add: @adds.to_a, remove: @removes.to_a}
          end
        end
      end
    end
  end
end
