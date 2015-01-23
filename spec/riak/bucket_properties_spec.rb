require 'spec_helper'
require 'riak/bucket_properties'

describe Riak::BucketProperties do
  let(:client){ instance_double 'Riak::Client' }
  let(:backend) do
    instance_double('Riak::Client::BeefcakeProtobuffsBackend').tap do |be|
      allow(client).to receive(:backend).and_yield be
    end
  end
  
  let(:props_operator) do
    instance_double('Riak::Client::BeefcakeProtobuffsBackend::BucketPropertiesOperator').
      tap do |po|
      allow(backend).to receive(:bucket_properties_operator).
        and_return(po)
    end
  end

  let(:bucket) do
    instance_double('Riak::Bucket').tap do |b|
      allow(b).to receive(:client).and_return(client)
      allow(b).to receive(:needs_type?).and_return(false)
    end
  end

  let(:typed_bucket) do
    instance_double('Riak::BucketTyped::Bucket').tap do |b|
      allow(b).to receive(:client).and_return(client)
    end
  end

  subject{ described_class.new bucket }

  it 'is initialized with a bucket' do
    p = nil
    expect{ p = described_class.new bucket }.to_not raise_error
    expect(p.client).to eq client
    expect(p.bucket).to eq bucket
  end

  it 'initialzies correctly with a bucket-typed bucket' do
    p = nil
    expect{ p = described_class.new typed_bucket }.to_not raise_error
    expect(p.client).to eq client
    expect(p.bucket).to eq typed_bucket
  end

  it 'provides hash-like access to properties' do
    expect(props_operator).to receive(:get).
      with(bucket).
      and_return('allow_mult' => true)

    expect(subject['allow_mult']).to be

    subject['allow_mult'] = false

    expect(props_operator).to receive(:put).
      with(bucket, hash_including('allow_mult' => false))

    subject.store
  end

  it 'merges properties from hashes' do
    expect(props_operator).to receive(:get).
      with(bucket).
      and_return('allow_mult' => true)

    expect(subject['allow_mult']).to be

    property_hash = { 'allow_mult' => false }
    expect{ subject.merge! property_hash }.to_not raise_error
    
    expect(props_operator).to receive(:put).
      with(bucket, hash_including('allow_mult' => false))

    subject.store
  end

  it 'merges properties from other bucket properties objects' do
    expect(props_operator).to receive(:get).
      with(bucket).
      and_return('allow_mult' => true)

    expect(subject['allow_mult']).to be

    other_props = described_class.new typed_bucket
    other_props.
      instance_variable_set :@cached_props, { 'allow_mult' => false}

    expect{ subject.merge! other_props }.to_not raise_error
    
    expect(props_operator).to receive(:put).
      with(bucket, hash_including('allow_mult' => false))

    subject.store
  end

  it 'reloads' do
    expect(props_operator).to receive(:get).
      with(bucket).
      and_return('allow_mult' => true)
    
    expect(subject['allow_mult']).to be

    expect(props_operator).to receive(:get).
      with(bucket).
      and_return('allow_mult' => false)

    expect{ subject.reload }.to_not raise_error

    expect(subject['allow_mult']).to_not be
  end
end
