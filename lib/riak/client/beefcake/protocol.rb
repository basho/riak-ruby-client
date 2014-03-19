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
