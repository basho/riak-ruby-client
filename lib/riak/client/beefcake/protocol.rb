require 'riak/client/beefcake/messages'
require 'riak/client/beefcake/message_codes'
module Riak
  class Client
    class BeefcakeProtobuffsBackend < ProtobuffsBackend
      class Protocol
        include Riak::Util::Translation
        attr_reader :socket

        def initialize(socket)
          @socket = socket
        end

        def write(code, message=nil)
          if code.is_a? Symbol
            code = BeefcakeMessageCodes.index code
          end

          serialized = serialize message

          header = [serialized.length + 1, code].pack 'NC'

          payload = header + serialized

          socket.write payload
          socket.flush
        end

        def receive
          header = socket.read 5
          
          raise t('pbc.failed_header') if header.nil?
          message_length, code = header.unpack 'NC'
          body_length = message_length - 1
          body = nil
          body = socket.read body_length if body_length > 0

          name = BeefcakeMessageCodes[code]

          return name, body
        end

        def expect(code, decoder_class=nil)
          code = BeefcakeMessageCodes[code] unless code.is_a? Symbol
          name, body = receive
          
          if name == :ErrorResp
            raise ProtobuffsErrorResponse.new body
          end

          if name != code
            raise ProtobuffsUnexpectedResponse.new name, code
          end

          return true if decoder_class.nil?

          return decoder_class.decode body
        end

        private

        def serialize(message)
          return '' if message.nil?
          return message if message.is_a? String
          return message.encode.to_s if message.is_a? Beefcake::Message

          raise ArgumentError.new t('pbc.unknown_serialize', message: message)
        end
      end
    end
  end
end
