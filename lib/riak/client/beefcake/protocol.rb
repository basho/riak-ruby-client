require 'riak/client/beefcake/messages'
require 'riak/client/beefcake/message_codes'
require 'riak/errors/failed_request'
module Riak
  class Client
    class BeefcakeProtobuffsBackend < ProtobuffsBackend
      class Protocol
        include Riak::Util::Translation
        attr_reader :socket

        def initialize(socket)
          @socket = socket
        end

        # Encodes and writes a Riak-formatted message, including protocol buffer
        # payload if given.
        # 
        # @param [Symbol, Integer] code the symbolic or numeric code for the 
        #   message
        # @param [Beefcake::Message, nil] message the protocol buffer message
        #   payload, or nil if the message carries no payload
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

        # Receives a Riak-formatted message, and returns the symbolic name of
        # the message along with the string payload from the network.
        #
        # @return [Array<Symbol, String>]
        def receive
          header = socket.read 5
          
          raise ProtobuffsFailedHeader.new if header.nil?
          message_length, code = header.unpack 'NC'
          body_length = message_length - 1
          body = nil
          body = socket.read body_length if body_length > 0

          name = BeefcakeMessageCodes[code]

          return name, body
        end

        # Receives a Riak-formatted message, checks the symbolic name against
        # the given code, decodes it if it matches, and can optionally return
        # success if the payload is empty.
        #
        # @param [Symbol] code the code for the message
        # @param [Class, nil] decoder_class the class to attempt to decode 
        #   the payload with
        # @param [Hash] options
        # @option options [Boolean] :empty_body_acceptable Whether to accept
        #   an empty body and not attempt decoding. In this case, this method
        #   will return the symbol `:empty` instead of a `Beefcake::Message`
        #   instance
        # @return [Beefcake::Message, :empty]
        # @raise {ProtobuffsErrorResponse} if the message from Riak was a
        #   255-ErrorResp
        # @raise {ProtobuffsUnexpectedResponse} if the message from riak did
        #   not match `code`
        def expect(code, decoder_class=nil, options={ })
          code = BeefcakeMessageCodes[code] unless code.is_a? Symbol
          name, body = receive
          
          if name == :ErrorResp
            raise ProtobuffsErrorResponse.new RpbErrorResp.decode(body)
          end

          if name != code
            raise ProtobuffsUnexpectedResponse.new name, code
          end

          return true if decoder_class.nil?

          return :empty if body.nil? && options[:empty_body_acceptable]

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
