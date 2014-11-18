require 'spec_helper'
require 'riak/bucket_type'

describe Riak::BucketType do
  let(:client){ Riak::Client.allocate }
  let(:name){ 'bucket_type_spec' }

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
end
