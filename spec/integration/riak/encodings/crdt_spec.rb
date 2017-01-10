# coding: utf-8
# Copyright 2010-present Basho Technologies, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'
require 'riak'
require 'riak/util/string'

describe 'Encoding and CRDTs', integration: true, search_config: true do
  shared_examples 'CRDTs with weird names' do
    let(:counter_bucket) do
      test_client.bucket_type(Riak::Crdt::DEFAULT_BUCKET_TYPES[:counter]).bucket(random_string)
    end
    let(:map_bucket) do
      test_client.bucket_type(Riak::Crdt::DEFAULT_BUCKET_TYPES[:map]).bucket(random_string)
    end
    let(:set_bucket) do
      test_client.bucket_type(Riak::Crdt::DEFAULT_BUCKET_TYPES[:set]).bucket(random_string)
    end
    let(:hll_bucket) do
      test_client.bucket_type(Riak::Crdt::DEFAULT_BUCKET_TYPES[:hll]).bucket(random_string)
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

      expect(random_string.encoding.name).to eq expected_encoding

      expect{ map = Riak::Crdt::Map.new map_bucket, random_string }.
        to_not raise_error

      expect(map).to be_a Riak::Crdt::Map

      expect(map.registers[random_string]).to be_nil

      expect{ map.registers[random_string] = random_string }.
        to_not raise_error

      expect(map.registers.length).to eq 1

      expect(map.registers[random_string]).to_not be_nil

      expect(Riak::Util::String.equal_bytes?(map.registers[random_string], random_string)).to be

      expect(random_string.encoding.name).to eq expected_encoding
    end

    it 'updates sets' do
      set = nil

      expect(random_string.encoding.name).to eq expected_encoding

      expect{ set = Riak::Crdt::Set.new set_bucket, random_string }.
        to_not raise_error

      expect(set).to be_a Riak::Crdt::Set

      expect(set.include?(random_string)).to_not be

      set.add random_string

      expect(set.include?(random_string)).to be

      set.remove random_string

      expect(set.include?(random_string)).to_not be

      expect(random_string.encoding.name).to eq expected_encoding
    end

    it 'updates hyper_log_logs', hll: true do
      begin
        hlls = test_client.bucket_type Riak::Crdt::DEFAULT_BUCKET_TYPES[:hll]
        hlls.properties
      rescue Riak::ProtobuffsErrorResponse
        skip('HyperLogLog bucket-type not found or active.')
      end

      hll = nil

      expect(random_string.encoding.name).to eq expected_encoding

      expect{ hll = Riak::Crdt::HyperLogLog.new hll_bucket, random_string }.to_not raise_error
      expect(hll).to be_a Riak::Crdt::HyperLogLog

      hll.add random_string

      expect(hll.value).to be_a(Integer)
      expect(hll.value).to eq 1

      expect(random_string.encoding.name).to eq expected_encoding
    end
  end

  describe 'with utf-8 strings' do
    let(:string){ "\xF0\x9F\x9A\xB4こんにちはสวัสดี" }
    let(:expected_encoding){ 'UTF-8' }
    let(:random_string){ string + random_key }

    include_examples 'CRDTs with weird names'
  end

  describe 'with binary strings' do
    let(:string){ "\xff\xff".force_encoding('binary') }
    let(:expected_encoding){ 'ASCII-8BIT' }
    let(:random_string){ string + random_key }

    include_examples 'CRDTs with weird names'
  end
end
