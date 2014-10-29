require 'spec_helper'
require 'riak/bucket_typed/robject'

describe Riak::BucketTyped::RObject do
  let(:client){ Riak::Client.allocate }
  let(:type){ Riak::BucketType.allocate }
  let(:bucket){ Riak::BucketTyped::Bucket.allocate }
  let(:key){ 'bucket_typed_robject_spec' }

  subject{ described_class.new bucket, key }

  it{ is_expected.to be_a Riak::RObject }
  it{ is_expected.to be_a described_class }

  it 'has a bucket and type' do
    expect(subject.bucket).to eq bucket
    expect(subject.type).to eq type
  end
end
