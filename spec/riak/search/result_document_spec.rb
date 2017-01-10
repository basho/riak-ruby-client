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
require 'riak/search/result_document'

describe Riak::Search::ResultDocument, crdt_search_fixtures: true do
  let(:key){ 'bitcask-10' }
  let(:bucket_name){ 'search_test' }
  let(:bucket_type_name){ 'yokozuna' }
  let(:score){ 43.21 }
  let(:other_field){ 'banana' }

  let(:client) do
    instance_double('Riak::Client').tap do |c|
      allow(c).to receive(:bucket_type).
                   with(bucket_type_name).
                   and_return(bucket_type)
      allow(c).to receive(:bucket_type).
                   with(maps_type_name).
                   and_return(maps_bucket_type)
    end
  end

  let(:bucket_type) do
    instance_double('Riak::BucketType').tap do |bt|
      allow(bt).to receive(:bucket).
                    with(bucket_name).
                    and_return(bucket)
      allow(bt).to receive(:data_type_class).
                    and_return(nil)
    end
  end

  let(:bucket) do
    instance_double('Riak::BucketTyped::Bucket').tap do |b|
      allow(b).to receive(:get).
        with(key).
        and_return(robject)
    end
  end

  let(:robject){ instance_double 'Riak::RObject' }

  let(:raw) do
    {
      "score"=>score,
      "_yz_rb"=>bucket_name,
      "_yz_rt"=>bucket_type_name,
      "_yz_rk"=>key,
      'other_field'=>other_field
    }
  end

  subject{ described_class.new client, raw }

  it 'has key, bucket, bucket type, and score accessors' do
    expect(subject.key).to eq key
    expect(subject.bucket).to eq bucket
    expect(subject.bucket_type).to eq bucket_type
    expect(subject.score).to eq score
  end

  it 'makes other yz fields available' do
    expect(subject[:other_field]).to eq other_field
  end

  describe 'identifying a key-value object' do
    it 'fetches the robject it identifies' do
      expect(subject.robject).to eq robject
    end

    it 'returns the data type class the document is' do
      expect(subject.type_class).to eq Riak::RObject
    end

    it 'refuses to return a CRDT' do
      expect{ subject.crdt }.to raise_error Riak::CrdtError::NotACrdt
    end
  end

  describe 'identifying a CRDT map object' do
    subject { map_results }

    it 'returns the data type class the document is' do
      expect(subject.type_class).to eq Riak::Crdt::Map
    end

    let(:fake_map){ instance_double 'Riak::Crdt::Map' }

    it 'fetches the map it identifies' do
      expect(Riak::Crdt::Map).
        to receive(:new).
            with(map_bucket, 'map-key', maps_bucket_type).
            and_return(fake_map).
            twice

      expect(subject.map).to eq fake_map
      expect(subject.crdt).to eq fake_map
    end

    it 'refuses to fetch a counter or set' do
      expect{ subject.counter }.
        to raise_error Riak::CrdtError::UnexpectedDataType
      expect{ subject.set }.
        to raise_error Riak::CrdtError::UnexpectedDataType
    end
  end
end
