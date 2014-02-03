require 'spec_helper'
require 'riak/client/beefcake/socket'

describe Riak::Client::BeefcakeProtobuffsBackend::BeefcakeSocket do
  let(:host){ 'host' }
  let(:pb_port){ 8087 }
  let(:tcp_socket_instance){ double 'TCPSocket' }

  let(:ssl){ OpenSSL::SSL }

  describe 'without authentication configured' do
    let(:options){ Hash.new }
    it 'should start a tcp connection and not start a tls connection' do
      TCPSocket.should_receive(:new).
        with(host, pb_port).
        and_return(tcp_socket_instance)

      tcp_socket_instance.should_receive(:setsockopt).
        with(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)

      ssl::SSLSocket.should_not_receive(:new)

      described_class.new host, pb_port
    end
  end

  describe 'with authentication configured' do
    let(:user){ 'user' }
    let(:password){ 'password' }
    let(:options) do
      {
        authentication: { 
          user: user,
          password: password
        } 
      }
    end
    let(:ssl_socket_instance){ double 'SSLSocket' }

    it 'should start a tcp and a tls connection, and send authentication info' do
      TCPSocket.should_receive(:new).
        with(host, pb_port).
        and_return(tcp_socket_instance)

      tcp_socket_instance.should_receive(:setsockopt).
        with(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)

      tcp_socket_instance.stub(:write)

      # StartTls
      tcp_socket_instance.should_receive(:read).
        with(5).
        and_return([1, 255].pack 'NC')

      ssl::SSLSocket.should_receive(:new).
        with(tcp_socket_instance).
        and_return(ssl_socket_instance)

      ssl_socket_instance.should_receive(:connect)

      ssl_socket_instance.stub(:write)

      # AuthResp
      ssl_socket_instance.should_receive(:read).
        with(5).
        and_return([1, 254].pack 'NC')

      # PingResp
      ssl_socket_instance.should_receive(:read).
        with(5).
        and_return([1, 2].pack 'NC')

      described_class.new host, pb_port, options
    end
  end
end
