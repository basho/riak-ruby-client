require 'spec_helper'
require 'riak/search'

describe 'Object-oriented Search API', test_client: true, integration: true, search_config: true do
  before :all do
    create_index
    configure_bucket
    load_corpus
  end

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
    it 'tests for index existence and content' do
      existing_index = Riak::Search::Index.new test_client, index_name
      expect(existing_index).to be_exists # auto predicate matcher

      nonexistent_index = Riak::Search::Index.new(test_client, "nonexist-#{random_key}")
      expect(nonexistent_index).to_not be_exists
    end

    it 'creates indexes' do
      new_index = Riak::Search::Index.new test_client, "search-spec-#{random_key}"
      expect(new_index).to_not be_exist
      expect{ new_index.create! }.to_not raise_error

      wait_until{ new_index.exists? }

      expect(new_index).to be_exists

      expect{ new_index.create! }.to raise_error Riak::SearchError::IndexExistsError
    end
  end

  describe 'schemas' do
    it 'tests for schema existence and content' do
      existing_schema = Riak::Search::Schema.new test_client, '_yz_default'
      expect(existing_schema).to be_exists

      nonexistent_schema = Riak::Search::Schema.new(test_client, "nonexist-#{random_key}")
      expect(nonexistent_schema).to_not be_exists
    end

    it 'creates schemas' do
      new_schema = Riak::Search::Schema.new test_client, "search-spec-#{random_key}"
      expect(new_schema).to_not be_exist
      expect{ new_schema.create! }.to_not raise_error

      wait_until{ new_schema.exists? }

      expect(new_schema).to be_exists

      expect{ new_schema.create! }.to raise_error Riak::SearchError::SchemaExistsError
    end
  end
end
