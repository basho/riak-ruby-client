require 'spec_helper'
require 'riak/search/index'

describe Riak::Search::Index do
  let(:index_name){ 'index_name' }
  let(:schema_name){ 'schema_name' }

  let(:index_exists_expectation) do
    expect(backend).to receive(:get_search_index).
      with(index_name).
      and_return(index_exists_response)
  end

  let(:index_exists_response) do
    instance_double(
                    'Riak::Client::BeefcakeProtobuffsBackend::RpbYokozunaIndexGetResp',
                    index: [{ name: index_name, schema: schema_name, n_val: 3 }]
                    )
  end

  let(:client){ instance_double 'Riak::Client' }
  let(:backend) do
    be = instance_double 'Riak::Client::BeefcakeProtobuffsBackend'
    allow(client).to receive(:backend).and_yield(be)
    be
  end

  subject { described_class.new client, index_name }

  it 'creates index objects with a client and index name' do
    expect{ described_class.new client, index_name }.to_not raise_error
  end

  it 'tests for index existence' do
    index_exists_expectation
    expect(subject).to be_exists
  end

  it 'permits index creation' do
    expect(backend).to receive(:get_search_index).
      with(index_name).
      and_raise(Riak::ProtobuffsFailedRequest.new(:not_found, 'not found'))

    expect(backend).to receive(:create_search_index).
      with(index_name, nil, nil, nil)

    expect{ subject.create! }.to_not raise_error
  end

  it 'raises an error when creating an index that already exists' do
    index_exists_expectation

    expect{ subject.create! }.
      to raise_error(Riak::SearchError::IndexExistsError)
  end

    it "spawns a query" do
      t = "some query term"
      expect(subject).to receive(:exists?).and_return(true)
      expect(query = subject.query(t)).to be_a Riak::Search::Query
      expect(query.term).to eq t
      expect(query.index).to eq subject
      expect(query.client).to eq subject.client
    end

  it 'returns data about the index' do
    index_exists_expectation

    expect(subject.n_val).to eq 3
    expect(subject.schema).to eq schema_name
  end
end
