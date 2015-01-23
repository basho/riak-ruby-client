require 'spec_helper'
require 'riak/search/schema'

describe Riak::Search::Schema do
  let(:schema_name){ 'schema_name' }
  let(:schema_content){ '<xml />' }

  let(:schema_exists_expectation) do
    expect(backend).to receive(:get_search_schema).
      with(schema_name).
      and_return(schema_exists_response)
  end

  let(:schema_exists_response) do
    resp = instance_double 'Riak::Client::BeefcakeProtobuffsBackend::RpbYokozunaSchema'
    allow(resp).to receive(:name).and_return(schema_name)
    allow(resp).to receive(:content).and_return(schema_content)
    
    resp
  end

  let(:client){ instance_double 'Riak::Client' }
  let(:backend) do
    be = instance_double 'Riak::Client::BeefcakeProtobuffsBackend'
    allow(client).to receive(:backend).and_yield be
    be
  end

  subject { described_class.new client, schema_name }

  it 'creates schema objects with a client and schema name' do
    expect{ described_class.new client, schema_name }.to_not raise_error
  end

  it 'tests for schema existence' do
    schema_exists_expectation
    expect(subject).to be_exists
  end

  it 'permits schema creation' do
    expect(backend).to receive(:get_search_schema).
      with(schema_name).
      and_return(nil)

    expect(backend).to receive(:create_search_schema).
      with(schema_name, schema_content).
      and_return(true)

    expect{ subject.create! schema_content }.to_not raise_error
  end

  it 'raises an error when creating a schema that already exists' do
    schema_exists_expectation
    
    expect{ subject.create! schema_content }.to raise_error(Riak::SearchError::SchemaExistsError)
  end

  it 'returns data about the schema' do
    schema_exists_expectation

    expect(subject.content).to eq schema_content
  end
end
