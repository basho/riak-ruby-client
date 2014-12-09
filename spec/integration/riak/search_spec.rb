require 'spec_helper'
require 'riak'

describe 'Object-oriented Search API', test_client: true, integration: true do
  include_context 'search corpus setup'
  let(:bucket){ @search_bucket }
  let(:index_name){ bucket.name }

  describe 'queries' do
    let(:index){ Riak::Search::Index.new test_client, index_name }

    it 'performs queries' do
      query = Riak::Search::Query.new test_client, index, 'operations'
      results = nil
      expect{ results = query.results }.to_not raise_error
      expect(results.raw).to_not be_empty 
      expect(results).to_not be_empty
    end

    it 'performs limited and sorted queries' do
      query = Riak::Search::Query.new test_client, index, 'operations'
      query.rows = 5
      results = nil
      expect{ results = query.results }.to_not raise_error
      expect(results.raw).to_not be_empty
      expect(results.length).to eq 5
    end
  end

  describe 'indexes' do
    it 'tests for index existence and content'
    it 'creates indexes'
  end

  describe 'schemas' do
    it 'tests for schema existence and content'
    it 'creates schemas'
  end
end
