require 'spec_helper'
require 'riak/bucket_typed/bucket'

describe Riak::BucketTyped::Bucket do
  let(:client){ Riak::Client.allocate }
  let(:type){ client.bucket_type 'type' }
  let(:name){ 'bucket_typed_bucket_spec' }

  subject{ described_class.new client, name, type }

  it 'initializes a typed RObject' do
    typed_robject = subject.new 'panther'
    expect(typed_robject).to be_a Riak::RObject
    expect(typed_robject).to be_a Riak::BucketTyped::RObject
    expect(typed_robject.key).to eq 'panther'
    expect(typed_robject.type).to eq type
  end
end
