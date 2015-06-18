# coding: utf-8
require 'spec_helper'
require 'riak'

describe 'Encoding and CRDTs', integration: true, search_config: true do
  shared_examples 'CRDTs with weird names' do
    let(:counter_bucket) do
      test_client.bucket_type('counters').bucket(random_string)
    end
    let(:map_bucket) do
      test_client.bucket_type('maps').bucket(random_string)
    end
    let(:set_bucket) do
      test_client.bucket_type('sets').bucket(random_string)
    end

    it 'creates counters' do
      counter = nil
      expect{ counter = Riak::Crdt::Counter.new counter_bucket, random_string }.
        to_not raise_error

      expect(counter).to be_a Riak::Crdt::Counter

      expect(value = counter.value).to be_a Numeric

      expect{ counter.increment }.to_not raise_error
      expect(counter.value).to eq value + 1
    end

    it 'updates registers in maps' do
      map = nil
      expect{ map = Riak::Crdt::Map.new map_bucket, random_string }.
        to_not raise_error

      expect(map).to be_a Riak::Crdt::Map

      expect(map.registers[random_string]).to be_nil
      expect{ map.registers[random_string] = random_string }.
        to_not raise_error

      expect(map.registers[random_string]).to eq random_string
    end

    it 'updates sets' do
      set = nil
      expect{ set = Riak::Crdt::Set.new set_bucket, random_string }.
        to_not raise_error

      expect(set).to be_a Riak::Crdt::Set

      expect(set.members).to_not include random_string

      set.add random_string

      expect(set.members).to include random_string

      set.remove random_string

      expect(set.members).to_not include random_string
    end
  end

  describe 'with utf-8 strings' do
    let(:string){ "\xF0\x9F\x9A\xB4こんにちはสวัสดี" }
    let(:random_string){ string + random_key }

    include_examples 'CRDTs with weird names'
  end

  describe 'with binary strings' do
    let(:string){ "\xff\xff".force_encoding('binary') }
    let(:random_string){ string + random_key }

    include_examples 'CRDTs with weird names'
  end
end
