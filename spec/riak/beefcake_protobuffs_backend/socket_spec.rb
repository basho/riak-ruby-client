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
      expect(TCPSocket).to receive(:new).
        with(host, pb_port).
        and_return(tcp_socket_instance)

      expect(tcp_socket_instance).to receive(:setsockopt).
        with(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)

      expect(ssl::SSLSocket).not_to receive(:new)

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
    let(:ssl_peer_cert){ double 'Peer Certificate' }
    let(:r509_cert){ double 'R509::Cert' }
    let(:rcv_instance){ double 'R509::Cert::Validator instance' }

    it 'should start a tcp and a tls connection, and send authentication info' do
      expect(TCPSocket).to receive(:new).
        with(host, pb_port).
        and_return(tcp_socket_instance)

      expect(tcp_socket_instance).to receive(:setsockopt).
        with(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)

      allow(tcp_socket_instance).to receive(:write)

      # StartTls
      expect(tcp_socket_instance).to receive(:read).
        with(5).
        and_return([1, 255].pack 'NC')

      expect(ssl::SSLSocket).to receive(:new).
        with(tcp_socket_instance, kind_of(OpenSSL::SSL::SSLContext)).
        and_return(ssl_socket_instance)

      expect(ssl_socket_instance).to receive(:connect)

      allow(ssl_socket_instance).to receive(:write)

      expect(ssl_socket_instance).to receive(:peer_cert).
        and_return(ssl_peer_cert)
      expect(R509::Cert).to receive(:new).
        with(cert: ssl_peer_cert).
        and_return(r509_cert)
      allow(r509_cert).to receive(:valid?).and_return(true)
      expect(R509::Cert::Validator).to receive(:new).
        with(r509_cert).
        and_return(rcv_instance)

      expect(rcv_instance).to receive(:validate).
        with(ocsp: false, crl: false, crl_file: nil).
        and_return(true)

      # AuthResp
      expect(ssl_socket_instance).to receive(:read).
        with(5).
        and_return([1, 254].pack 'NC')

      # PingResp
      expect(ssl_socket_instance).to receive(:read).
        with(5).
        and_return([1, 2].pack 'NC')

      described_class.new host, pb_port, options
    end

    it 'should pass pass TLS options through to OpenSSL' do
      options[:authentication][:ca_file] = 'spec/support/certs/ca.crt'
      options[:authentication][:key] = 'spec/support/certs/client.key'

      expect(TCPSocket).to receive(:new).
        with(host, pb_port).
        and_return(tcp_socket_instance)

      expect(tcp_socket_instance).to receive(:setsockopt).
        with(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)

      allow(tcp_socket_instance).to receive(:write)

      # StartTls
      expect(tcp_socket_instance).to receive(:read).
        with(5).
        and_return([1, 255].pack 'NC')

      expect(ssl::SSLSocket).to receive(:new) do |sock, ctx|
        expect(sock).to eq tcp_socket_instance
        expect(ctx).to be_a OpenSSL::SSL::SSLContext
        expect(ctx.key).to be_a OpenSSL::PKey::PKey
        expect(ctx.ca_file).to eq 'spec/support/certs/ca.crt'
        
        ssl_socket_instance
      end

      expect(ssl_socket_instance).to receive(:connect)

      allow(ssl_socket_instance).to receive(:write)

      expect(ssl_socket_instance).to receive(:peer_cert).
        and_return(ssl_peer_cert)
      expect(R509::Cert).to receive(:new).
        with(cert: ssl_peer_cert).
        and_return(r509_cert)
      allow(r509_cert).to receive(:valid?).and_return(true)
      expect(R509::Cert::Validator).to receive(:new).
        with(r509_cert).
        and_return(rcv_instance)

      expect(rcv_instance).to receive(:validate).
        with(ocsp: false, crl: false, crl_file: nil).
        and_return(true)

      # AuthResp
      expect(ssl_socket_instance).to receive(:read).
        with(5).
        and_return([1, 254].pack 'NC')

      # PingResp
      expect(ssl_socket_instance).to receive(:read).
        with(5).
        and_return([1, 2].pack 'NC')

      described_class.new host, pb_port, options
    end
  end
end
