require 'spec_helper'
require 'riak/search/result_collection'

describe Riak::Search::ResultCollection, crdt_search_fixtures: true do
  let(:client) do
    instance_double('Riak::Client').tap do |c|
      allow(c).to receive(:bucket_type).
        with(bucket_type_name).
        and_return(bucket_type)
    end
  end

  let(:bucket_type) do
    instance_double('Riak::BucketType').tap do |bt|
      allow(bt).to receive(:bucket).
        with(bucket_name).
        and_return(bucket)
    end
  end

  let(:bucket) do
    instance_double('Riak::BucketTyped::Bucket')
  end

  let(:backend) do
    instance_double('Riak::Client::BeefcakeProtobuffsBackend').tap do |be|
      allow(client).to receive(:backend).and_yield(be)
    end
  end

  let(:results_hash) do
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
                 "_yz_rk"=>"bitcask-4"},
               map_raw
              ]
    }
  end

  let(:bucket_name){ 'search_test-1419261439-ew70sak2qr' }
  let(:bucket_type_name){ 'yokozuna' }
  let(:first_key){ 'bitcask-10' }
  let(:first_result) do
    instance_double('Riak::RObject').tap do |o|
      allow(o).to receive(:key).and_return(first_key)
    end
  end

  let(:fetch_first_expectation) do
    expect(bucket).to receive(:get).with(first_key).and_return(first_result)
  end

  subject{ described_class.new client, results_hash }

  it 'is creatable with a search results hash' do
    expect{ described_class.new client, results_hash }.to_not raise_error
  end

  it 'exposes the raw search results hash' do
    expect(subject.raw).to eq results_hash
  end

  it 'exposes the max score and entry scores' do
    expect(subject.max_score).to eq results_hash['max_score']
    expect(subject.docs.first.score).to eq Float(
                                                 results_hash['docs'].
                                                 first['score'])
  end

  it 'fetches individual documents on demand' do
    fetch_first_expectation
    allow(bucket_type).to receive(:data_type_class).and_return nil

    expect(subject.first).to eq first_result
  end
end
