require 'spec_helper'
require 'riak/bucket_properties'

describe Riak::BucketProperties do
  let(:client){ instance_double 'Riak::Client' }
  let(:backend) do
    instance_double('Riak::Client::BeefcakeProtobuffsBackend').tap do |be|
      allow(client).to receive(:backend).and_yield be
    end
  end
  let(:bucket) do
    instance_double('Riak::Bucket').tap do |b|
      allow(b).to receive(:needs_type?).and_return(false)
    end
  end

  let(:typed_bucket) do
    instance_double('Riak::BucketTyped::Bucket')
  end

  subject{ described_class.new client, bucket }

  it 'is initialized with a client and bucket' do
    p = nil
    expect{ p = described_class.new client, bucket }.to_not raise_error
    expect(p.client).to eq client
    expect(p.bucket).to eq bucket
  end

  it 'initialzies correctly with a bucket-typed bucket' do
    p = nil
    expect{ p = described_class.new client, typed_bucket }.to_not raise_error
    expect(p.client).to eq client
    expect(p.bucket).to eq typed_bucket
  end

  it 'provides hash-like access to properties' do
    expect(backend).to receive(:get_bucket_props).
      with(bucket, hash_excluding(:type)).
      and_return('allow_mult' => true)

    expect(subject['allow_mult']).to be

    subject['allow_mult'] = false

    expect(backend).to receive(:set_bucket_props).
      with(bucket, hash_including('allow_mult' => false), nil)

    subject.store
  end

  it 'merges properties from hashes' do
    expect(backend).to receive(:get_bucket_props).
      with(bucket, hash_excluding(:type)).
      and_return('allow_mult' => true)

    expect(subject['allow_mult']).to be

    property_hash = { 'allow_mult' => false }
    expect{ subject.merge! property_hash }.to_not raise_error
    
    expect(backend).to receive(:set_bucket_props).
      with(bucket, hash_including('allow_mult' => false), nil)

    subject.store
  end

  it 'merges properties from other bucket properties objects' do
    expect(backend).to receive(:get_bucket_props).
      with(bucket, hash_excluding(:type)).
      and_return('allow_mult' => true)

    expect(subject['allow_mult']).to be

    other_props = described_class.new client, typed_bucket
    other_props.
      instance_variable_set :@cached_props, { 'allow_mult' => false}

    expect{ subject.merge! other_props }.to_not raise_error
    
    expect(backend).to receive(:set_bucket_props).
      with(bucket, hash_including('allow_mult' => false), nil)

    subject.store
  end

  it 'reloads' do
    expect(backend).to receive(:get_bucket_props).
      with(bucket, hash_excluding(:type)).
      and_return('allow_mult' => true)
    
    expect(subject['allow_mult']).to be

    expect(backend).to receive(:get_bucket_props).
      with(bucket, hash_excluding(:type)).
      and_return('allow_mult' => false)

    expect{ subject.reload }.to_not raise_error

    expect(subject['allow_mult']).to_not be
  end
end
