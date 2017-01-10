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
    # The {InnerFlag} is a boolean member of a {Map}. Since flag operations are
    # extremely simple, this object simply provides internal API methods for
    # {TypedCollection} to use.
    #
    # @api private
    class InnerFlag
      def self.new(parent, value = false)
        ensure_boolean value

        return value
      end

      def self.update(value)
        ensure_boolean value

        Operation::Update.new.tap do |op|
          op.value = value
          op.type = :flag
        end
      end

      def self.delete
        Operation::Delete.new.tap do |op|
          op.type = :flag
        end
      end

      private
      def self.ensure_boolean(value)
        return if value.is_a? TrueClass
        return if value.is_a? FalseClass

        raise FlagError, t('crdt.flag.not_boolean')
      end

      class FlagError < ArgumentError
      end
    end
  end
end
