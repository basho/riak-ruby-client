require 'spec_helper'
require 'riak'

describe 'Secure Protobuffs', test_client: true, integration: true do
  describe 'without security enabled on Riak', no_security: true do
    it 'should connect normally without authentication configured' do
      expect(test_client.security?).to_not be

      expect(test_client.ping).to be
    end

    it 'should refuse to connect with authentication configured' do
      config = test_client_configuration.dup
      config[:authentication] = { username: 'user', password: 'password' }

      secure_client = Riak::Client.new config
      
      expect{ secure_client.ping }.to raise_error
    end
  end

  describe 'with security enabled on Riak', yes_security: true do
    it 'should connect normally with authentication configured' do
      expect(test_client.security?).to be

      expect(test_client.ping).to be
    end

    it 'should refuse to connect without authentication configured' do
      config = test_client_configuration.dup

      config.delete :authentication

      plaintext_client = Riak::Client.new config

      expect{ plaintext_client.ping }.to raise_error
    end

    it "should refuse to connect if the server cert isn't recognized"
    it "should refuse to connect if the server cert is revoked"
  end
end
