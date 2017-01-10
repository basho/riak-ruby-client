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
  module Util
    # Methods comparing strings
    module String
      def equal_bytes?(a, b)
        return true if a.nil? && b.nil?

        return false unless a.respond_to?(:bytesize)
        return false unless b.respond_to?(:bytesize)
        return false unless a.bytesize == b.bytesize

        return false unless a.respond_to?(:bytes)
        return false unless b.respond_to?(:bytes)

        b1 = a.bytes.to_a
        b2 = b.bytes.to_a
        i = 0
        loop do
          c1 = b1[i]
          c2 = b2[i]
          return false unless c1 == c2
          i += 1
          break if i > b1.length
        end
        true
      end

      module_function :equal_bytes?
    end
  end
end
