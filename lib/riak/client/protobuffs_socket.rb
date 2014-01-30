module Riak
  class Client
    class ProtobuffsBackend
      # A factory class for making sockets, whether secure or not
      # @api private
      class ProtobuffsSocket
        include BeefcakeMessageCodes
        # Only create class methods, don't initialize
        class << self
          def new(host, port, options={})
            return start_tcp_socket(host, port) unless options[:authentication]
          end

          private
          def start_tcp_socket(host, port)
            TCPSocket.new(host, port).tap do |sock|
              sock.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)
            end
          end

          def start_tls_socket(host, port, authentication)
            TlsInitiator.new(start_tcp_socket(host, port)).tls_socket
          end

          class TlsInitiator
            BC = BeefcakeProtobuffsBackend

            def initialize(tcp_socket, authentication)
              @sock = @tcp = tcp_socket
              @auth = authentication
            end

            def tls_socket
              start_tls
              send_authentication
              validate_connection
              return @tls
            end

            private
            def start_tls
              write_message :StartTls
              expect_message :StartTls
              # Swap the tls socket in for the tcp socket, so write_message and
              # read_message continue working
              @sock = @tls = OpenSSL::SSL::SSLSocket.new @tcp
              @tls.connect
            end

            def send_authentication
              req = BC::RpbAuthReq authentication
              write_message :AuthReq, req.encode
              expect_message :AuthResp
            end

            def validate_connection
              write_message :PingReq
              expect_message :PingResp
            end

            def write_message(code, message='')
              if code.is_a? Symbol
                code = BeefcakeMessageCodes.index code
              end

              header = [message.length+1, code].pack 'NC'
              @sock.write header + message
            end

            def read_message
              header = @sock.read 5
              raise SocketError, "Unexpected EOF during TLS init" if header.nil?
              len, code = header.unpack 'NC'
              decode = BeefcakeMessageCodes[code]
              message = socket.read(len - 1)
              return decode, message
            end

            def expect_message(expected_code)
              if expected_code.is_a? Numeric
                expected_code = BeefcakeMessageCodes[code]
              end

              candidate_code, message = read_message
              return message if expected_code == candidate_code

              raise "Wanted #{expected_code.inspect}, got #{candidate_code.inspect} and #{message.inspect}"
            end
          end
        end
      end
    end
  end
end
