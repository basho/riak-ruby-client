# coding: utf-8
require 'spec_helper'
require 'riak'

describe 'Encoding and Riak Search', integration: true, search_config: true do
  let(:bucket_type){ test_client.bucket_type 'yokozuna' }

  let(:utf8_encoding){ Encoding.find 'utf-8' }
  let(:utf8_string){ "\xF0\x9F\x9A\xB4こんにちはสวัสดี" }
  let(:random_utf8_string){ utf8_string + random_key }
  let(:utf8_bucket){ bucket_type.bucket random_utf8_string }

  let(:binary_encoding){ Encoding.find 'binary' }
  let(:binary_string){ "\xff\xff".force_encoding('binary') }
  let(:random_binary_string){ binary_string + random_key }
  let(:binary_bucket){ bucket_type.bucket random_binary_string }

  describe 'with utf-8 strings' do
    it 'creates schemas' do
      schema = nil
      expect do
        schema = Riak::Search::Schema.new test_client, random_utf8_string
      end.to_not raise_error

      expect(schema).to be_a Riak::Search::Schema

      expect{ schema.create! schema_xml random_utf8_string }.to_not raise_error

      schema2 = Riak::Search::Schema.new test_client, random_utf8_string
      expect(schema2).to be_exists
    end

    it 'refuses to create indexes' do
      index = nil
      expect do
        index = Riak::Search::Index.new test_client, random_utf8_string
      end.to_not raise_error

      expect(index).to be_a Riak::Search::Index

      expect{ index.create! }.to raise_error /Invalid character/
    end

    it 'queries non-weird indexes' do
      create_index

      props = Riak::BucketProperties.new utf8_bucket
      props['search_index'] = index_name
      props.store

      wait_until do
        props.reload
        props['search_index'] == index_name
      end

      robj = utf8_bucket.new random_utf8_string
      robj.content_type = 'text/plain'
      robj.raw_data = <<EOD
This is due to the write-once, append-only nature of the Bitcask database files.
High throughput, especially when writing an incoming stream of random items
Because the data being written doesn't need to be ordered on disk and because
the log structured design allows for minimal disk head movement during writes
these operations generally saturate the I/O and disk bandwidth.
EOD
      robj.store

      results = nil
      wait_until do
        results = index.query('bitcask').results
        !results.empty?
      end
      expect(results).to_not be_empty
      expect(results.docs.first.bucket_type).to eq robj.bucket.type
      expect(results.docs.first.bucket).to eq robj.bucket
      expect(results.docs.first.key.bytes).to eq robj.key.bytes
    end
  end

  describe 'with binary strings' do
    it 'refuses to create schemas' do
      schema = nil
      expect do
        schema = Riak::Search::Schema.new test_client, random_binary_string
      end.to_not raise_error

      expect(schema).to be_a Riak::Search::Schema

      # yz will refuse to create files with names that aren't valid utf-8
      expect{ schema.create! schema_xml random_binary_string }.
        to raise_error /bad_character/
    end


    it 'refuses to create indexes' do
      index = nil
      expect do
        index = Riak::Search::Index.new test_client, random_binary_string
      end.to_not raise_error

      expect(index).to be_a Riak::Search::Index

      expect{ index.create! }.to raise_error /Invalid character/
    end

    # left here for reference: yz can't index documents with \xff\xff in the
    # key, or presumably bucket name either
    #     it 'queries non-weird indexes' do
    #       create_index

    #       props = Riak::BucketProperties.new binary_bucket
    #       props['search_index'] = index_name
    #       props.store

    #       wait_until do
    #         props.reload
    #         props['search_index'] == index_name
    #       end

    #       robj = binary_bucket.new random_binary_string
    #       robj.content_type = 'text/plain'
    #       robj.raw_data = <<EOD
    # This is due to the write-once, append-only nature of the Bitcask database files.
    # High throughput, especially when writing an incoming stream of random items
    # Because the data being written doesn't need to be ordered on disk and because
    # the log structured design allows for minimal disk head movement during writes
    # these operations generally saturate the I/O and disk bandwidth.
    # EOD
    #       robj.store

    #       results = nil
    #       wait_until do
    #         results = index.query('bitcask').results
    #         !results.empty?
    #       end
    #       expect(results).to_not be_empty
    #       expect(results.docs.first.bucket_type).to eq robj.bucket.type
    #       expect(results.docs.first.bucket).to eq robj.bucket
    #       expect(results.docs.first.key.bytes).to eq robj.key.bytes
    #     end
  end
end
