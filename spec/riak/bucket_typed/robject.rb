require 'spec_helper'
require 'riak/bucket_typed/robject'

describe Riak::BucketTyped::RObject do
  let(:client){ Riak::Client.allocate }
  let(:type){ client.bucket_type 'bucket_typed_robject_spec' }
  let(:bucket){ type.bucket 'fruits' }
  let(:key){ 'plantain' }

  subject{ described_class.new bucket, key }

  it{ is_expected.to be_a Riak::RObject }
  it{ is_expected.to be_a described_class }

  it 'has a bucket and type' do
    expect(subject.bucket).to eq bucket
    expect(subject.type).to eq type
  end
end
