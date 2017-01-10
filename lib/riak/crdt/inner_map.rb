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
    # A map that exists inside a {TypedCollection} inside another map.
    class InnerMap
      attr_reader :counters, :flags, :maps, :registers, :sets

      attr_accessor :name

      # The parent of this counter.
      #
      # @api private
      attr_reader :parent

      # @api private
      def initialize(parent, value = {})
        @parent = parent
        @value = value.symbolize_keys

        initialize_collections
      end

      # @api private
      def operate(inner_operation)
        wrapped_operation = Operation::Update.new.tap do |op|
          op.value = inner_operation
          op.type = :map
        end

        @parent.operate(name, wrapped_operation)
      end

      def pretty_print(pp)
        pp.object_group self do
          %w{counters flags maps registers sets}.each do |h|
            pp.comma_breakable
            pp.text "#{h}="
            pp.pp send h
          end
        end
      end

      def pretty_print_cycle(pp)
        pp.text "InnerMap"
      end

      def to_value_h
        %w{counters flags maps registers sets}.map do |k|
          [k, send(k).to_value_h]
        end.to_h
      end

      alias :value :to_value_h

      # @api private
      def self.delete
        Operation::Delete.new.tap do |op|
          op.type = :map
        end
      end

      def context?
        @parent.context?
      end

      private
      def initialize_collections
        @counters = TypedCollection.new InnerCounter, self, @value[:counters]
        @flags = TypedCollection.new InnerFlag, self, @value[:flags]
        @maps = TypedCollection.new InnerMap, self, @value[:maps]
        @registers = TypedCollection.new InnerRegister, self, @value[:registers]
        @sets = TypedCollection.new InnerSet, self, @value[:sets]
      end
    end
  end
end
