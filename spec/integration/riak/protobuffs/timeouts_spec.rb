require 'spec_helper'

describe 'Protocol Buffers', test_client: true do
  describe 'timeouts' do

    # let(:bucket){ random_bucket 'timeouts' }
    #
    # before do
    #   first = bucket.new 'first'
    #   first.data = 'first'
    #   first.content_type = 'text/plain'
    #   first.store
    #
    #   second = bucket.new 'second'
    #   second.data = 'second'
    #   second.content_type = 'text/plain'
    #   second.store
    # end

    it 'raises error on connect timeout' do
      config = test_client_configuration.dup

      # unroutable TEST-NET (https://tools.ietf.org/html/rfc5737)
      config[:host] = '192.0.2.0'

      config[:connect_timeout] = 0.0001
      client = Riak::Client.new(config)

      expect do
        client.ping
      end.to raise_error RuntimeError, /Operation timed out/
    end

    it 'raises error on read timeout' do
      config = test_client_configuration.dup
      config[:read_timeout] = 0.0001
      client = Riak::Client.new(config)

      expect do
        client.ping
      end.to raise_error RuntimeError, /Operation timed out/
    end

    it 'raises error on write timeout' do
      config = test_client_configuration.dup
      config[:write_timeout] = 0.0001
      client = Riak::Client.new(config)

      bucket = client.bucket('timeouts')
      first = bucket.new 'first'
      # write enough data to grow beyond socket buffer capacity
      first.data = SecureRandom.urlsafe_base64(10_000_000)
      first.content_type = 'text/plain'

      expect do
        first.store
      end.to raise_error RuntimeError, /Operation timed out/
    end
  end
end
