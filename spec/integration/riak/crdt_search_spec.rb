require 'spec_helper'
require 'riak/search'

describe 'CRDT Search API', crdt_search_config: true do
  describe 'querying maps' do
    subject { Riak::Search::Query.new test_client, index_name, 'frijoles' }

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

    it 'raises typeerrors on the set, counter, and robject accessors' do
      expect{ subject.docs.first.robject }.to raise_error Riak::SearchError::UnexpectedResultError
      expect{ subject.docs.first.counter }.to raise_error Riak::SearchError::UnexpectedResultError
      expect{ subject.docs.first.set }.to raise_error Riak::SearchError::UnexpectedResultError
    end
  end

  describe 'querying sets'
  describe 'querying counters'

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
