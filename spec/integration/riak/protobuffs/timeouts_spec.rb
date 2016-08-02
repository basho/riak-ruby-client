require 'socket'
require 'spec_helper'

require 'riak/client/beefcake/messages'
require 'riak/client/beefcake/protocol'

describe 'Protocol Buffers', test_client: true, integration: true do
  if RUBY_VERSION >= '2.0.0'
    describe 'timeouts' do
      it 'raises error on connect timeout' do
        # unroutable TEST-NET (https://tools.ietf.org/html/rfc5737)
        config = {}
        config[:host] = '192.0.2.0'
        config[:pb_port] = 65535

        config[:connect_timeout] = 0.0001
        client = Riak::Client.new(config)

        expect do
          client.ping
        end.to raise_error RuntimeError, /timed out/
      end

      it 'raises error on read timeout' do
        ok_to_continue = false
        quitting = false
        port = 0

        server = nil
        thr = Thread.new do
          server = TCPServer.new port
          port = server.addr[1]
          ok_to_continue = true
          loop do
            begin
              Thread.start(server.accept) do |s|
                loop do
                  p = Riak::Client::BeefcakeProtobuffsBackend::Protocol.new s
                  begin
                    msgname, _body = p.receive
                  rescue IOError
                    break if quitting
                    raise
                  end
                  case msgname
                  when :PingReq
                    sleep 0.5
                    p.write :PingResp
                  else
                    $stderr.puts("unknown msgname: #{msgname}")
                  end
                end
              end
            rescue IOError
              break if quitting
              raise
            end
          end
        end

        loop do
          break if ok_to_continue
          sleep 0.1
        end
        ok_to_continue = false

        config = {}
        config[:pb_port] = port
        config[:client_id] = port
        config[:read_timeout] = 0.0001
        client = Riak::Client.new(config)

        max_ping_attempts = 16
        ping_count = 0
        loop do
          begin
            client.ping
            ping_count += 1
            break if ping_count > max_ping_attempts
          rescue RuntimeError => e
            break if e.message =~ /timed out/
          end
          sleep 0.5
        end

        quitting = true
        server.close
        thr.join

        expect(ping_count).to be < max_ping_attempts
      end

      it 'raises error on write timeout' do
        ok_to_continue = false
        quitting = false
        port = 0

        server = nil
        thr = Thread.new do
          server = TCPServer.new port
          port = server.addr[1]
          ok_to_continue = true
          loop do
            begin
              Thread.start(server.accept) do |s|
                loop do
                  p = Riak::Client::BeefcakeProtobuffsBackend::Protocol.new s
                  begin
                    msgname, _body = p.receive
                  rescue IOError
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
                  else
                    $stderr.puts("unknown msgname: #{msgname}")
                  end
                end
              end
            rescue IOError
              break if quitting
              raise
            end
          end
        end

        loop do
          break if ok_to_continue
          sleep 0.1
        end
        ok_to_continue = false

        config = {}
        config[:pb_port] = port
        config[:client_id] = port
        config[:write_timeout] = 0.0001
        client = Riak::Client.new(config)

        bucket = client.bucket('timeouts')

        max_store_attempts = 16
        store_count = 0
        loop do
          begin
            obj = bucket.new "obj-#{store_count}"
            # write enough data to grow beyond socket buffer capacity
            obj.data = SecureRandom.urlsafe_base64(10_000_000)
            obj.content_type = 'text/plain'
            obj.store
            store_count += 1
            break if store_count > max_store_attempts
          rescue RuntimeError => e
            break if e.message =~ /timed out/
          end
          sleep 0.5
        end

        quitting = true
        server.close
        thr.join

        expect(store_count).to be < max_store_attempts
      end
    end
  else
    skip 'not supported in this version of Ruby'
  end
end
