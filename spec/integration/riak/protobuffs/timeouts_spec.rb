require 'socket'
require 'spec_helper'

require 'riak/client/beefcake/messages'
require 'riak/client/beefcake/protocol'

describe 'Protocol Buffers', test_client: true, integration: true do
  describe 'timeouts' do
    it 'raises error on connect timeout' do
      config = test_client_configuration.dup
      # unroutable TEST-NET (https://tools.ietf.org/html/rfc5737)
      config[:host] = '192.0.2.0'

      config[:connect_timeout] = 0.0001
      client = Riak::Client.new(config)

      expect do
        client.ping
      end.to raise_error RuntimeError, /timed out/
    end

    it 'raises error on read timeout' do
      config = test_client_configuration.dup

      config[:read_timeout] = 0.0001
      client = Riak::Client.new(config)

      expect do
        client.ping
      end.to raise_error RuntimeError, /timed out/
    end

    it 'raises error on write timeout' do
      ok_to_continue = false
      quitting = false
      port = 0

      server = nil
      thr = Thread.new {
        server = TCPServer.new port
        port = server.addr[1]
        ok_to_continue = true
        put_count = 0
        loop do
          begin
            Thread.start(server.accept) do |s|
              loop do
                p = Riak::Client::BeefcakeProtobuffsBackend::Protocol.new s
                begin
                  msgname, body = p.receive
                rescue IOError => e
                  break if quitting
                  raise
                end
                case msgname
                when :PingReq
                  p.write :PingResp
                when :GetServerInfoReq
                  r = Riak::Client::BeefcakeProtobuffsBackend::RpbGetServerInfoResp.new
                  r.node = 'dev1@127.0.0.1'.force_encoding('BINARY')
                  r.server_version = '2.1.4'.force_encoding('BINARY')
                  p.write :GetServerInfoResp, r
                when :PutReq
                  r = Riak::Client::BeefcakeProtobuffsBackend::RpbPutResp.new
                  p.write :PutResp, r
                  ok_to_continue = true if put_count > 1
                  put_count += 1
                else
                  $stderr.puts("unknown msgname: #{msgname}")
                end
              end
            end
          rescue IOError => e
            break if quitting
            raise
          end
        end
      }

      loop do
        break if ok_to_continue
        sleep 0.1
      end
      ok_to_continue = false

      config = test_client_configuration.dup

      config[:write_timeout] = 0.00001
      config[:pb_port] = port
      config[:client_id] = port
      client = Riak::Client.new(config)

      bucket = client.bucket('timeouts')
      obj = bucket.new 'first'
      # write enough data to grow beyond socket buffer capacity
      obj.data = SecureRandom.urlsafe_base64(10_000_000)
      obj.content_type = 'text/plain'

      expect do
        obj.store
      end.to raise_error RuntimeError, /timed out/

      loop do
        break if ok_to_continue
        sleep 0.1
      end

      quitting = true
      server.close
      thr.join
    end
  end
end
