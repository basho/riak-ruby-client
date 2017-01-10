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

    # A distributed set containing strings, using the Riak 2 Data Types feature and Hyper Log Log algorithm
    class HyperLogLog < Base
      include Util::String

      # Create a HLL instance. The bucket type is determined by the first of
      # these sources:
      #
      # 1. The `bucket_type` String argument
      # 2. A {BucketTyped::Bucket} as the `bucket` argument
      # 3. The `Crdt::Base::DEFAULT_BUCKET_TYPES[:hll]` entry
      #
      # @param bucket [Bucket] the {Riak::Bucket} for this set
      # @param [String, nil] key The name of the set. A nil key makes
      #        Riak assign a key.
      # @param [String] bucket_type The bucket type for this HLL datatype
      # @param options [Hash]
      def initialize(bucket, key, bucket_type = nil, options = {})
        super(bucket, key, bucket_type || :hll, options)
      end

      # Gets the current HLL value from Riak
      #
      # @return [Integer]
      def value
        reload if dirty?
        @value
      end
      alias :cardinality :value

      def batch
        batcher = BatchHyperLogLog.new self

        yield batcher

        operate batcher.operations
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
          op.type = :hll
          op.value = { direction => element }
        end
      end

      class BatchHyperLogLog
        def initialize(base)
          @base = base
          @adds = ::Set.new
        end

        def add(element)
          @adds.add element
        end

        def to_a
          @adds.to_a
        end

        def value
          @adds
        end

        def operations
          Operation::Update.new.tap do |op|
            op.type = :hll
            op.value = {add: @adds.to_a}
          end
        end
      end
    end
  end
end
