require 'riak/client/beefcake/crdt/map_loader'

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
        def load(bucket, key, bucket_type, options={})
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

        private
        # Convert the protobuffs response into low-level Ruby objects.
        def rubyfy(response)
          return nil_rubyfy(response.type) if response.value.nil?
          case response.type
          when DtFetchResp::DataType::COUNTER
            response.value.counter_value
          when DtFetchResp::DataType::SET
            ::Set.new response.value.set_value
          when DtFetchResp::DataType::MAP
            MapLoader.new(response.value.map_value).rubyfy
            
          end
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
          end
        end
      end
    end
  end
end
