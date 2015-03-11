require 'spec_helper'
require 'riak/search/result_document'

describe Riak::Search::ResultDocument do
  let(:key){ 'bitcask-10' }
  let(:bucket_name){ 'search_test' }
  let(:bucket_type_name){ 'yokozuna' }
  let(:score){ 43.21 }
  let(:other_field){ 'banana' }

  let(:client) do
    instance_double('Riak::Client').tap do |c|
      allow(c).to receive(:bucket_type).
                   with(bucket_type_name).
                   and_return(bucket_type)
      allow(c).to receive(:bucket_type).
                   with(maps_type_name).
                   and_return(maps_bucket_type)
    end
  end

  let(:bucket_type) do
    instance_double('Riak::BucketType').tap do |bt|
      allow(bt).to receive(:bucket).
                    with(bucket_name).
                    and_return(bucket)
      allow(bt).to receive(:data_type_class).
                    and_return(nil)
    end
  end

  let(:maps_type_name){ 'maps' }
  let(:maps_bucket_type) do
    instance_double('Riak::BucketType').tap do |bt|
      allow(bt).to receive(:bucket).
                    with(bucket_name).
                    and_return(map_bucket)
      allow(bt).to receive(:data_type_class).
                    and_return(Riak::Crdt::Map)
    end
  end

  let(:bucket) do
    instance_double('Riak::BucketTyped::Bucket').tap do |b|
      allow(b).to receive(:get).
        with(key).
        and_return(robject)
    end
  end

  let(:map_bucket) do
    instance_double('Riak::BucketTyped::Bucket')
  end

  let(:robject){ instance_double 'Riak::RObject' }

  let(:raw) do
    {
      "score"=>score,
      "_yz_rb"=>bucket_name,
      "_yz_rt"=>bucket_type_name,
      "_yz_rk"=>key,
      'other_field'=>other_field
    }
  end

  let(:map_raw) do
    {
      'score'=>score,
      '_yz_rb'=>bucket_name,
      '_yz_rt'=>maps_type_name,
      '_yz_rk'=>'map-key'
    }
  end

  subject{ described_class.new client, raw }

  let(:crdt_subject) do
    described_class.new client, map_raw
  end

  it 'has key, bucket, bucket type, and score accessors' do
    expect(subject.key).to eq key
    expect(subject.bucket).to eq bucket
    expect(subject.bucket_type).to eq bucket_type
    expect(subject.score).to eq score
  end

  it 'makes other yz fields available' do
    expect(subject[:other_field]).to eq other_field
  end

  it 'fetches the robject it identifies' do
    expect(subject.robject).to eq robject
  end

  it 'returns the data type class the document is' do
    expect(subject.type_class).to eq Riak::RObject

    expect(crdt_subject.type_class).to eq Riak::Crdt::Map
  end
end
