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
    it 'finds CRDTs'
    it 'provides access through appropriate accessors'
    it 'allows looping through each object'
    it 'allows looping through each kind of object'
  end

  describe 'querying both CRDTs and RObjects' do
    it 'finds CRDTs and RObjects'
    it 'provides access through appropriate accessors'
    it 'allows looping through each object'
    it 'allows looping through each kind of object'
  end
end
