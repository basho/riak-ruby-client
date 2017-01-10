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

module Riak
  module Crdt
    # The {InnerCounter} lives inside a {Map}, or an {InnerMap} inside of a
    # {Map}, and is accessed through a {TypedCollection}.
    #
    # Much like the {Riak::Crdt::Counter}, it provides an integer value that can
    # be incremented and decremented.
    class InnerCounter
      # The name of this counter inside a map.
      #
      # @api private
      attr_accessor :name

      # The value of this counter.
      #
      # @return [Integer] counter value
      attr_reader :value
      alias :to_i :value

      # The parent of this counter.
      #
      # @api private
      attr_reader :parent

      # @api private
      def initialize(parent, value = 0)
        @parent = parent
        @value = value
      end

      # Increment the counter.
      #
      # @param [Integer] amount How much to increment the counter by.
      def increment(amount = 1)
        @parent.increment name, amount
      end

      # Decrement the counter. Opposite of increment.
      #
      # @param [Integer] amount How much to decrement from the counter.
      def decrement(amount = 1)
        increment -amount
      end

      # Perform multiple increments against this counter, and collapse
      # them into a single operation.
      #
      # @yieldparam [BatchCounter] batch_counter actually collects the
      #                            operations.
      def batch
        batcher = BatchCounter.new

        yield batcher

        increment batcher.accumulator
      end

      def pretty_print(pp)
        pp.object_group self do
          pp.breakable
          pp.pp value
        end
      end

      # @api private
      def self.update(increment)
        Operation::Update.new.tap do |op|
          op.value = increment
          op.type = :counter
        end
      end

      # @api private
      def self.delete
        Operation::Delete.new.tap do |op|
          op.type = :counter
        end
      end
    end
  end
end
