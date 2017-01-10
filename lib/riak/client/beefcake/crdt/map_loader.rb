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

class Riak::Client::BeefcakeProtobuffsBackend
  class CrdtLoader
    class MapLoader
      def self.for_value(resp)
        return nil unless resp.map_value
        new resp.map_value
      end

      def initialize(map_value)
        @value = map_value
      end

      def rubyfy
        accum = {
          counters: {},
          flags: {},
          maps: {},
          registers: {},
          sets: {}
        }

        contents_loop @value, accum
      end

      private

      def rubyfy_inner(accum, map_value)
        destination = accum[:maps][map_value.field.name]
        if destination.nil?
          destination = accum[:maps][map_value.field.name] = {
            counters: {},
            flags: {},
            maps: {},
            registers: {},
            sets: {}
          }
        end

        contents_loop map_value.map_value, destination
      end

      def contents_loop(rolling_value, destination)
        return destination if rolling_value.nil?

        rolling_value.each do |inner|
          case inner.field.type
          when MapField::MapFieldType::COUNTER
            destination[:counters][inner.field.name] = inner.counter_value
          when MapField::MapFieldType::FLAG
            destination[:flags][inner.field.name] = inner.flag_value
          when MapField::MapFieldType::MAP
            rubyfy_inner destination, inner
          when MapField::MapFieldType::REGISTER
            destination[:registers][inner.field.name] = inner.register_value
          when MapField::MapFieldType::SET
            destination[:sets][inner.field.name] = ::Set.new inner.set_value
          end
        end

        return destination
      end
    end
  end
end
