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
            rubyfy_map response.value.map_value
          end
        end

        # Convert a top-level map into a Ruby {Hash} of hashes.
        def rubyfy_map(map_value)
          accum = {
            counters: {},
            flags: {},
            maps: {},
            registers: {},
            sets: {}
          }

          rubyfy_map_contents map_value, accum
        end

        # Convert a map inside another map into a Ruby {Hash}.
        def rubyfy_inner_map(accum, map_value)
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
          
          rubyfy_map_contents map_value.map_value, destination
        end

        # Load the contents of a map into Ruby hashes.
        def rubyfy_map_contents(map_value, destination)
          return destination if map_value.nil?
          map_value.each do |inner_mv|
            case inner_mv.field.type
            when MapField::MapFieldType::COUNTER
              destination[:counters][inner_mv.field.name] = inner_mv.counter_value
            when MapField::MapFieldType::FLAG
              destination[:flags][inner_mv.field.name] = inner_mv.flag_value
            when MapField::MapFieldType::MAP
              rubyfy_inner_map destination, inner_mv
            when MapField::MapFieldType::REGISTER
              destination[:registers][inner_mv.field.name] = inner_mv.register_value
            when MapField::MapFieldType::SET
              destination[:sets][inner_mv.field.name] = ::Set.new inner_mv.set_value
            end
          end

          return destination
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
