require 'spec_helper'
require 'riak'
require 'riak/errors/connection_error'
require 'cert_validator/errors'

describe 'Secure Protobuffs', test_client: true, integration: true do
  let(:config){ test_client_configuration.dup }
  describe 'without security enabled on Riak', no_security: true do
    it 'connects normally without authentication configured' do
      expect(test_client.security?).to_not be

      expect{test_client.ping}.to_not raise_error
    end

    it 'refuses to connect with authentication configured' do
      with_auth_config = config.dup
      with_auth_config[:authentication] = { user: 'user', password: 'password' }

      secure_client = Riak::Client.new with_auth_config
      
      expect{ secure_client.ping }.to raise_error(Riak::TlsError)
    end
  end

  describe 'with security enabled on Riak', yes_security: true do
    it 'connects normally with authentication configured' do
      secure_client = Riak::Client.new config

      expect(secure_client.security?).to be

      expect{secure_client.ping}.to_not raise_error
    end

    it 'refuses to connect without authentication configured' do
      no_auth_config = config.dup
      no_auth_config.delete :authentication

      plaintext_client = Riak::Client.new no_auth_config

      expect{ plaintext_client.ping }.
        to(raise_error(Riak::ProtobuffsFailedRequest,
                       /security is enabled/i))
    end

    it "refuses to connect if the server cert isn't recognized" do
      broken_auth_config = config.dup
      broken_auth_config[:authentication] = broken_auth_config[:authentication].dup
      # this CA has never ever been used to sign a key
      broken_auth_config[:authentication][:ca_file] =
        File.join('support', 'certs', 'empty_ca.crt')

      bugged_crypto_client = Riak::Client.new broken_auth_config

      expect{ bugged_crypto_client.ping }.
        to(raise_error(OpenSSL::SSL::SSLError,
                       /certificate verify failed/i))
    end

    it "refuses to connect if the server cert is revoked" do
      revoked_auth_config = config.dup
      revoked_auth_config[:authentication] = revoked_auth_config[:authentication].dup

      revoked_auth_config[:authentication][:crl_file] =
        File.expand_path(File.join(__dir__, '..', '..', 'support', 'certs', 'server.crl'))
      revoked_auth_config[:authentication][:crl] = true

      revoked_auth_client = Riak::Client.new revoked_auth_config

      expect{ revoked_auth_client.ping }.
        to(raise_error(Riak::TlsError,
                       /revoked/i))
    end
  end

  describe 'with client certificate security enabled on Riak', yes_security: true do
    it 'connects normally with authentication configured' do
      client_cert_config = config.dup
      client_cert_config[:authentication] = 
        client_cert_config[:authentication].dup

      client_cert_config[:authentication][:client_ca] = client_cert_config[:authentication]['ca_file']

      client_cert_config[:authentication][:cert] = 'spec/support/certs/client.crt'
      client_cert_config[:authentication][:key] = 'spec/support/certs/client.key'

      client_cert_config[:authentication][:user] = 'certuser'
      client_cert_config[:authentication][:password] = ''

      cert_client = Riak::Client.new client_cert_config

      expect{ cert_client.ping }.to_not raise_error
    end
  end
end
