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
    class BatchCounter
      attr_reader :accumulator

      def initialize
        @accumulator = 0
      end

      def increment(amount = 1)
        @accumulator += amount
      end

      def decrement(amount = 1)
        increment -amount
      end
    end
  end
end
