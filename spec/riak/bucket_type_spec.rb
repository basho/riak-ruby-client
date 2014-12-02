require 'spec_helper'
require 'riak/bucket_type'

describe Riak::BucketType do
  let(:client){ Riak::Client.allocate }
  let(:name){ 'bucket_type_spec' }
  let(:backend) do
    double('Backend').tap do |backend|
      allow(client).to receive(:backend).and_yield(backend)
    end
  end

  subject{ described_class.new client, name }

  it 'is created with a client and name' do
    expect{ described_class.new client, name }.to_not raise_error
  end

  it 'returns a typed bucket' do
    typed_bucket = subject.bucket 'empanadas'
    expect(typed_bucket).to be_a Riak::Bucket
    expect(typed_bucket).to be_a Riak::BucketTyped::Bucket
    expect(typed_bucket.name).to eq 'empanadas'
    expect(typed_bucket.type).to eq subject
  end

  let(:sample_props){ { allow_mult: true } }

  it 'has properties' do
    expect(backend).to receive(:get_bucket_type_props).with(name).and_return(sample_props)
    expect(props = subject.properties).to be_a Hash
    expect(props[:allow_mult]).to be
  end
end
