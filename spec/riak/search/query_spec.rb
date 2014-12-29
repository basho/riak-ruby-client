require 'spec_helper'
require 'riak/search/query'

describe Riak::Search::Query do
  let(:client){ instance_double 'Riak::Client' }
  let(:index) do 
    instance_double(
                    'Riak::Search::Index',
                    name: index_name).tap do |i|
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
    expect{ described_class.new client, index_name, term }.to_not raise_error
  end

  it 'errors when querying with a non-existent index'
  it 'allows specifying other query options on creation'
  it 'allows specifying query options with accessors'

  it 'returns a ResultCollection' do
    expect(client).to receive(:backend).and_yield(backend)
    expect(backend).to receive(:search).
      with(index_name, term, instance_of(Hash)).
      and_return(raw_results)

    expect(subject.results).to be_a Riak::Search::ResultCollection
  end
end
