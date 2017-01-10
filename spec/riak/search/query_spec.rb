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
require 'riak/search/query'

describe Riak::Search::Query do
  let(:client) do
    instance_double('Riak::Client').tap do |c|
      allow(c).to receive(:backend).and_yield(backend)
    end
  end
  let(:index) do
    instance_double(
                    'Riak::Search::Index',
                    name: index_name,
                    'exists?' => true).tap do |i|
      allow(i).to receive(:is_a?).with(String).and_return(false)
      allow(i).to receive(:is_a?).with(Riak::Search::Index).and_return(true)
    end
  end
  let(:backend){ instance_double 'Riak::Client::BeefcakeProtobuffsBackend' }

  let(:index_name){ 'yokozuna' }
  let(:term){ 'bitcask' }

  let(:raw_results) do
    {
      "max_score"=>0.7729485034942627,
      "num_found"=>3,
      "docs"=>[
               {"score"=>"7.72948500000000038312e-01",
                 "_yz_rb"=>"search_test-1419261439-ew70sak2qr",
                 "_yz_rt"=>"yokozuna",
                 "_yz_rk"=>"bitcask-10"},
               {"score"=>"2.35808490000000009479e-01",
                 "_yz_rb"=>"search_test-1419261439-ew70sak2qr",
                 "_yz_rt"=>"yokozuna",
                 "_yz_rk"=>"bitcask-9"},
               {"score"=>"6.73738599999999937529e-02",
                 "_yz_rb"=>"search_test-1419261439-ew70sak2qr",
                 "_yz_rt"=>"yokozuna",
                 "_yz_rk"=>"bitcask-4"}
              ]
    }
  end

  subject { described_class.new client, index, term }

  it 'creates query objects with a client, index, and query string' do
    expect{ described_class.new client, index, term }.to_not raise_error
  end

  it 'creates query objects with a client, index name, and query string' do
    class_double('Riak::Search::Index', new: index).as_stubbed_const
    allow(index).to receive(:is_a?).with(Riak::Search::Index).and_return(true)

    expect{ described_class.new client, index_name, term }.to_not raise_error
  end

  it 'errors when querying with a non-existent index' do
    expect(index).to receive(:exists?).and_return(false)
    expect{ described_class.new client, index, term }.to raise_error(Riak::SearchError::IndexNonExistError)
  end

  it 'allows specifying other query options on creation' do
    expect(backend).to receive(:search).
      with(index_name, term, hash_including(rows: 5)).
      and_return(raw_results)

    q = described_class.new client, index, term, rows: 5
    expect{ q.results }.to_not raise_error
  end

  it 'allows specifying query options with accessors' do
    expect(backend).to receive(:search).
      with(index_name, term, hash_including(rows: 5)).
      and_return(raw_results)

    subject.rows = 5
    expect{ subject.results }.to_not raise_error
  end

  it 'returns a ResultCollection' do
    expect(backend).to receive(:search).
      with(index_name, term, instance_of(Hash)).
      and_return(raw_results)

    expect(subject.results).to be_a Riak::Search::ResultCollection
  end
end
