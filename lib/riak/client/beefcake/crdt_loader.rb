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

require 'riak/client/beefcake/crdt/counter_loader'
require 'riak/client/beefcake/crdt/hyper_log_log_loader'
require 'riak/client/beefcake/crdt/map_loader'
require 'riak/client/beefcake/crdt/set_loader'

module Riak
  class Client
    class BeefcakeProtobuffsBackend

      # Returns a new {CrdtLoader} for deserializing a protobuffs response full
      # of CRDTs.
      # @api private
      def crdt_loader
        return CrdtLoader.new self
      end

      # Loads, and deserializes CRDTs from protobuffs into Ruby hashes,
      # sets, strings, and integers.
      # @api private
      class CrdtLoader
        include Util::Translation

        attr_reader :backend, :context

        def initialize(backend)
          @backend = backend
        end

        # Perform the protobuffs request and return a deserialized CRDT.
        def load(bucket, key, bucket_type, options = {})
          bucket = bucket.name if bucket.is_a? ::Riak::Bucket
          fetch_args = options.merge(
                                     bucket: bucket,
                                     key: key,
                                     type: bucket_type
                                     )
          request = DtFetchReq.new fetch_args

          response = backend.protocol do |p|
            p.write :DtFetchReq, request
            p.expect :DtFetchResp, DtFetchResp
          end

          @context = response.context
          rubyfy response
        end

        def get_loader_for_value(value)
          return nil if value.nil?

          [CounterLoader, HyperLogLogLoader, MapLoader, SetLoader].map do |loader|
            loader.for_value value
          end.compact.first
        end

        private
        # Convert the protobuffs response into low-level Ruby objects.
        def rubyfy(response)
          loader = get_loader_for_value response.value
          return nil_rubyfy(response.type) if loader.nil?

          return loader.rubyfy
        end

        # Sometimes a CRDT is empty, provide a sane default.
        def nil_rubyfy(type)
          case type
          when DtFetchResp::DataType::COUNTER
            0
          when DtFetchResp::DataType::SET
            ::Set.new
          when DtFetchResp::DataType::MAP
            {
              counters: {},
              flags: {},
              maps: {},
              registers: {},
              sets: {},
            }
          when DtFetchResp::DataType::HLL
            0
          end
        end
      end
    end
  end
end
