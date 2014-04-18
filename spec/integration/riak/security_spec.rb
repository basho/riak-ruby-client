require 'spec_helper'
require 'riak'

describe 'Secure Protobuffs', test_client: true, integration: true do
  let(:config){ test_client_configuration.dup }
  describe 'without security enabled on Riak', no_security: true do
    it 'should connect normally without authentication configured' do
      expect(test_client.security?).to_not be

      expect(test_client.ping).to be
    end

    it 'should refuse to connect with authentication configured' do
      config[:authentication] = { user: 'user', password: 'password' }

      secure_client = Riak::Client.new config
      
      expect{ secure_client.ping }.to raise_error(Riak::TlsError)
    end
  end

  describe 'with security enabled on Riak', yes_security: true do
    it 'should connect normally with authentication configured' do
      secure_client = Riak::Client.new config

      expect(secure_client.security?).to be

      expect{secure_client.ping}.to be
    end

    it 'should refuse to connect without authentication configured' do
      config.delete :authentication

      plaintext_client = Riak::Client.new config

      expect{ plaintext_client.ping }.to raise_error
    end

    it "should refuse to connect if the server cert isn't recognized" do
      # this CA has never ever been used to sign a key
      config[:authentication][:ca_file] =
        File.join('support', 'certs', 'empty_ca.crt')

      bugged_crypto_client = Riak::Client.new config

      expect{ bugged_crypto_client.ping }.to raise_error
    end

    it "should refuse to connect if the server cert is revoked"
  end
end
