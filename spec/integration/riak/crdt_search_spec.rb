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
require 'riak/search'

describe 'CRDT Search API', crdt_search_config: true do
  describe 'querying maps' do
    let(:query) { index.query 'arroz_register:frijoles' }

    before(:all) do
      expect(first_map).to be
    end

    subject{ query.results }

    it 'finds maps' do
      expect(subject.length).to be > 0
    end

    it 'provides access to maps through the #map accessor' do
      expect(subject.maps.first).to eq first_map
      expect(subject.docs.first.map).to eq first_map
    end

    it 'provides access to maps through the #crdt accessor' do
      expect(subject.crdts.first).to eq first_map
      expect(subject.docs.first.crdt).to eq first_map
    end

    it 'provides access to maps through the #object accessor' do
      expect(subject.first).to eq first_map
      expect(subject.docs.first.object).to eq first_map
    end

    it 'raises errors on the set, counter, and robject accessors' do
      expect{ subject.docs.first.robject }.
        to raise_error Riak::SearchError::UnexpectedResultError
      expect{ subject.docs.first.counter }.
        to raise_error Riak::CrdtError::UnexpectedDataType
      expect{ subject.docs.first.set }.
        to raise_error Riak::CrdtError::UnexpectedDataType
    end
  end

  describe 'querying sets' do
    let(:query) { index.query 'set:frijoles' }

    before(:all) do
      expect(first_set).to be
    end

    subject{ query.results }

    it 'finds sets' do
      expect(subject.length).to be > 0
    end

    it 'provides access to sets through the #set accessor' do
      expect(subject.sets.first).to eq first_set
      expect(subject.docs.first.set).to eq first_set
    end

    it 'provides access to sets through the #object accessor' do
      expect(subject.first).to eq first_set
      expect(subject.docs.first.object).to eq first_set
    end

    it 'raises errors on the counter, map, and robject accessors' do
      expect{ subject.docs.first.robject }.
        to raise_error Riak::SearchError::UnexpectedResultError
      expect{ subject.docs.first.counter }.
        to raise_error Riak::CrdtError::UnexpectedDataType
      expect{ subject.docs.first.map }.
        to raise_error Riak::CrdtError::UnexpectedDataType
    end
  end

  describe 'querying counters' do
    let(:query) { index.query 'counter:83475' }

    before(:all) do
      expect(first_counter).to be
    end

    subject{ query.results }

    it 'finds counters' do
      expect(subject.length).to be > 0
    end

    it 'provides access to counters through the #counter accessor' do
      expect(subject.counters.first).to eq first_counter
      expect(subject.docs.first.counter).to eq first_counter
    end

    it 'provides access to counters through the #object accessor' do
      expect(subject.first).to eq first_counter
      expect(subject.docs.first.object).to eq first_counter
    end

    it 'raises errors on the counter, map, and robject accessors' do
      expect{ subject.docs.first.robject }.
        to raise_error Riak::SearchError::UnexpectedResultError
      expect{ subject.docs.first.set }.
        to raise_error Riak::CrdtError::UnexpectedDataType
      expect{ subject.docs.first.map }.
        to raise_error Riak::CrdtError::UnexpectedDataType
    end
  end

  describe 'querying multiple kinds of CRDT' do
    let(:query) do
      index.query 'arroz_register:frijoles OR set:frijoles OR counter:83475'
    end
    subject{ query.results }

    before(:all) do
      expect(first_counter).to be
      expect(first_map).to be
      expect(first_set).to be
    end

    it 'finds CRDTs' do
      expect(subject.length).to be >= 3
    end

    it 'provides access through appropriate accessors' do
      expect(subject.counters.first).to eq first_counter
      expect(subject.maps.first).to eq first_map
      expect(subject.sets.first).to eq first_set
      expect(subject.crdts).to include first_counter
      expect(subject.crdts).to include first_map
      expect(subject.crdts).to include first_set
    end

    it 'allows looping through each object' do
      # I worry that this may be order-dependent and occasionally fail
      expect{ |b| subject.crdts.each &b }.
        to yield_successive_args(first_counter, first_map, first_set)
    end

    it 'allows looping through each kind of object' do
      expect{ |b| subject.counters.each &b }.to yield_with_args(first_counter)
      expect{ |b| subject.maps.each &b }.to yield_with_args(first_map)
      expect{ |b| subject.sets.each &b }.to yield_with_args(first_set)
    end
  end

  describe 'querying both CRDTs and RObjects' do
    let(:query) do
      index.query 'arroz_register:frijoles OR set:frijoles OR counter:83475 OR "bitcask"'
    end
    subject{ query.results }

    before(:all) do
      load_corpus
      expect(first_counter).to be
      expect(first_map).to be
      expect(first_set).to be
    end

    let(:first_robject){ subject.robjects.first }

    it 'finds CRDTs and RObjects' do
      expect(subject.objects).to include first_counter
      expect(subject.objects).to include first_map
      expect(subject.objects).to include first_set
      expect(subject.objects).to include first_robject
    end

    it 'provides access through appropriate accessors' do
      expect(subject.crdts).to_not include first_robject
      expect(subject.robjects).to_not include first_counter
      expect(subject.robjects).to_not include first_map
      expect(subject.robjects).to_not include first_set
    end
  end
end
