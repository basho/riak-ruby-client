# coding: utf-8
require 'spec_helper'
require 'riak'

describe 'Encoding and Riak KV', integration: true, test_client: true do
  let(:bucket_type){ test_client.bucket_type 'yokozuna' }

  let(:utf8_encoding){ Encoding.find 'utf-8' }
  let(:utf8_string){ "\xF0\x9F\x9A\xB4こんにちはสวัสดี" }
  let(:random_utf8_string){ utf8_string + random_key }
  let(:utf8_bucket){ bucket_type.bucket random_utf8_string }

  let(:binary_encoding){ Encoding.find 'binary' }
  let(:binary_string){ "\xff\xff".force_encoding('binary') }
  let(:random_binary_string){ binary_string + random_key }
  let(:binary_bucket){ bucket_type.bucket random_binary_string }

  it 'encodes the test strings correctly' do
    expect(utf8_string.encoding).to eq utf8_encoding
    expect(random_utf8_string.encoding).to eq utf8_encoding
    expect(binary_string.encoding).to eq binary_encoding
    expect(random_binary_string.encoding).to eq binary_encoding
  end

  describe 'key-value operations' do
    it 'allows utf-8 strings in bucket and key names, values, and 2i' do
      expect(utf8_bucket).to be_a Riak::Bucket
      expect(robj = utf8_bucket.new(random_utf8_string)).to be_a Riak::RObject
      robj.content_type = 'text/plain'
      robj.data = random_utf8_string
      robj.indexes['cat_bin'] = [random_utf8_string, 'asdf']
      expect{ robj.store }.to_not raise_error

      expect(robj2 = utf8_bucket.get(random_utf8_string)).to be_a Riak::RObject
      expect(robj2.data).to eq random_utf8_string

      robj.raw_data = random_utf8_string
      robj.store
      robj2.reload
      expect(robj2.raw_data).to eq random_utf8_string
      expect(robj2.indexes['cat_bin']).to include 'asdf'
      expect(robj2.indexes['cat_bin']).
        to include random_utf8_string.force_encoding('binary')

      expect(utf8_bucket.get_index 'cat_bin', 'asdf').
        to include random_utf8_string.force_encoding('binary')
      expect(utf8_bucket.get_index 'cat_bin', random_utf8_string).
        to include random_utf8_string.force_encoding('binary')

      # riak gives us binary-encoding back, which is working as intended
      expect(utf8_bucket.keys).
        to include random_utf8_string.force_encoding('binary')
    end

    it 'allows binary strings in bucket and key names and values' do
      expect(binary_bucket).to be_a Riak::Bucket
      expect(robj = binary_bucket.new(random_binary_string)).
        to be_a Riak::RObject
      robj.content_type = 'text/plain'
      robj.data = random_binary_string
      robj.indexes['cat_bin'] = [random_binary_string, 'asdf']
      expect{ robj.store }.to_not raise_error

      expect(robj2 = binary_bucket.get(random_binary_string)).
        to be_a Riak::RObject
      expect(robj2.data).to eq random_binary_string

      robj.raw_data = random_binary_string
      robj.store
      robj2.reload
      expect(robj2.raw_data).to eq random_binary_string

      expect(binary_bucket.get_index 'cat_bin', 'asdf').
        to include random_binary_string
      expect(binary_bucket.get_index 'cat_bin', random_binary_string).
        to include random_binary_string

      expect(binary_bucket.keys).to include random_binary_string
    end
  end
end
