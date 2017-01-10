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
    # A map that queues up its operations for the parent {Map} to send to
    # Riak all at once.
    class BatchMap
      attr_reader :counters, :flags, :maps, :registers, :sets

      # @api private
      def initialize(parent)
        @parent = parent
        @queue = []

        initialize_collections
      end

      # @api private
      def operate(operation)
        @queue << operation
      end

      # @api private
      def operations
        @queue.map do |q|
          Operation::Update.new.tap do |op|
            op.type = :map
            op.value = q
          end
        end
      end

      private
      def initialize_collections
        @counters = @parent.counters.reparent self
        @flags = @parent.flags.reparent self
        @maps = @parent.maps.reparent self
        @registers = @parent.registers.reparent self
        @sets = @parent.sets.reparent self
      end
    end
  end
end
