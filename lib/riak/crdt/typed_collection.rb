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
    # A collection of elements of a given type inside a {Map}.
    class TypedCollection
      ALREADY_WRAPPED = ::Set.new [InnerCounter, InnerFlag, InnerMap]
      NEEDS_NAME = ::Set.new [InnerCounter, InnerSet, InnerMap]
      INITIALIZE_NIL = ::Set.new [InnerRegister]

      # @api private
      def initialize(type, parent, contents = {})
        @type = type
        @parent = parent
        contents = {} if contents.nil?
        stringified_contents = contents.stringify_keys
        @contents = materialize_contents stringified_contents
      end

      def pretty_print(pp)
        pp.object_group self do
          pp.breakable
          pp.text inspect_name
          pp.comma_breakable
          pp.text 'parent='
          @parent.pretty_print_cycle(pp)
          pp.comma_breakable
          pp.text 'contents='
          pp.pp @contents
        end
        # buf = []
        # buf << inspect_name
        # buf <<
        # buf << "contents={#{inspect_contents}}"
        # "#<#{self.class.name} #{buf.join ' '}>"
      end

      def pretty_print_cycle(pp)
        pp.object_group self do
          pp.breakable
          @parent.pretty_print_cycle(pp)
        end
      end

      def inspect_name
        "contains=#{content_name}"
      end

      def pretty_print_contents(_pp)
        @contents.map do |k, v|
          "#{k}=>#{v.inspect}"
        end.join ', '
      end

      def content_name
        @type.name
      end

      # @api private
      def reparent(new_parent)
        self.class.new(@type,
                       new_parent,
                       @contents)
      end

      # Check if a value for a given key exists in this map.
      #
      # @param [String] key the key to check for
      # @return [Boolean] if the key is inside this collection
      def include?(key)
        @contents.include? normalize_key(key)
      end

      # Get the value for a given key
      #
      # @param [String] key the key to get the value for
      # @return the value for the given key
      def [](key)
        key = normalize_key(key)
        if include? key
          candidate = @contents[key]
          return candidate unless candidate.respond_to? :parent
          return candidate if candidate.parent == self
        end

        return nil if initialize_nil?

        new_instance = @type.new self
        new_instance.name = key if needs_name?

        new_instance
      end

      # Set the value for a given key. Operation of this method
      # is only defined for {InnerCounter}, {InnerRegister}, and
      # {InnerFlag} types.
      #
      # @param [String] key the key to set a new value for
      # @param [Boolean, String, Integer] value the value to set at the key,
      #        or in the case of counters, the amount to increment
      def []=(key, value)
        key = normalize_key(key)

        operation = @type.update value
        operation.name = key

        result = @parent.operate operation

        @contents[key] = @type.new self, value
        @contents[key].name = key if needs_name?

        result
      end

      alias_method :increment, :[]=

      def length
        @contents.length
      end

      # Remove the entry from the map.
      #
      # @param [String] key the key to remove from the map
      def delete(key)
        key = normalize_key(key)
        operation = @type.delete
        operation.name = key

        @parent.operate operation

        @contents.delete key
      end

      # @api private
      def operate(key, inner_operation)
        key = normalize_key(key)

        inner_operation.name = key

        @parent.operate inner_operation
      end

      # Does this set have the context necessary to remove elements?
      #
      # @return [Boolean] if the set has a defined context
      def context?
        !!@parent.context?
      end

      def to_value_h
        return @contents unless NEEDS_NAME.include? @type

        @contents.map do |k, v|
          [k, v.value]
        end.to_h
      end

      private

      def normalize_key(unnormalized_key)
        unnormalized_key.to_s.dup.force_encoding('binary')
      end

      def initialize_nil?
        INITIALIZE_NIL.include? @type
      end

      def needs_name?
        NEEDS_NAME.include? @type
      end

      def materialize_contents(stringified_contents)
        stringified_contents.keys.inject(Hash.new) do |new_contents, key|
          new_contents.tap do |c|
            content = stringified_contents[key]
            if ALREADY_WRAPPED.include? content.class
              c[key] = content
            else
              c[key] = @type.new self, content
            end
            c[key].name = key if needs_name?
          end
        end
      end
    end
  end
end
