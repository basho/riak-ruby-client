module Riak
  class Client
    class BeefcakeProtobuffsBackend
      def crdt_loader
        return CrdtLoader.new self
      end
      
      class CrdtLoader
        include Util::Translation

        attr_reader :backend, :context

        def initialize(backend)
          @backend = backend
        end

        def load(bucket, key, bucket_type, options={})
          bucket = bucket.name if bucket.is_a? ::Riak::Bucket
          fetch_args = options.merge(
                                     bucket: bucket,
                                     key: key,
                                     type: bucket_type
                                     )
          request = DtFetchReq.new fetch_args

          backend.write_protobuff :DtFetchReq, request

          response = decode
          @context = response.context
          rubyfy response
        end

        private
        def decode
          header = socket.read 5

          if header.nil?
            backend.teardown
            raise SocketError, t('pbc.unexpected_eof')
          end
          
          msglen, msgcode = header.unpack 'NC'

          if BeefcakeProtobuffsBackend::MESSAGE_CODES[msgcode] != :DtFetchResp
            backend.teardown
            raise SocketError, t('pbc.wanted_dt_fetch_resp')
          end

          message = socket.read(msglen - 1)

          DtFetchResp.decode message
        end

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

        def rubyfy_map(map_value)
          accum = {
            counters: {},
            flags: {},
            maps: {},
            registers: {},
            sets: {}
          }
          map_value.each do |mv|
            case mv.field.type
            when MapField::MapFieldType::COUNTER
              accum[:counters][mv.field.name] = mv.counter_value
            when MapField::MapFieldType::FLAG
              accum[:flags][mv.field.name] = mv.flag_value
            when MapField::MapFieldType::MAP
              rubyfy_inner_map accum, mv
            when MapField::MapFieldType::REGISTER
              accum[:registers][mv.field.name] = mv.register_value
            when MapField::MapFieldType::SET
              accum[:sets][mv.field.name] = ::Set.new mv.set_value
            end
          end

          return accum
        end

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
          
          map_value.map_value.each do |inner_mv|
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
        end

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

        def socket
          backend.socket
        end
      end
    end
  end
end
