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
          case response.type
          when DtFetchResp::DataType::COUNTER
            response.value.counter_value
          when DtFetchResp::DataType::SET
            ::Set.new response.value.set_value
          when DtFetchResp::DataType::MAP
            response.value.map_value
          end
        end

        def socket
          backend.socket
        end
      end
    end
  end
end
