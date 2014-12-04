require 'spec_helper'
require 'riak'

describe "CRDT configuration", integration: true, test_client: true do
  let(:bucket) { random_bucket }

  it "allows default bucket-types to be configured for each data type" do
    expect(Riak::Crdt::Set.new(bucket, 'set').bucket_type).to eq 'sets'

    Riak::Crdt::DEFAULT_BUCKET_TYPES[:set] = 'new_set_default'
    expect(Riak::Crdt::Set.new(bucket, 'set').bucket_type).to eq 'new_set_default'

    Riak::Crdt::DEFAULT_BUCKET_TYPES[:set] = 'sets'
    expect(Riak::Crdt::Set.new(bucket, 'set').bucket_type).to eq 'sets'
  end

  describe 'overriding bucket-types' do
    let(:name){ 'other_counters' }
    let(:type){ test_client.bucket_type name }
    let(:typed_bucket){ type.bucket bucket.name }

    it "overrides with a string" do
      ctr = Riak::Crdt::Counter.new(bucket, 'ctr', name)
      expect(ctr.bucket_type).to eq name
    end

    it "overrides with a typed bucket" do
      ctr = Riak::Crdt::Counter.new(typed_bucket, 'ctr')
      expect(ctr.bucket_type).to eq name
    end

    it "overrides with a bucket type object" do
      ctr = Riak::Crdt::Counter.new(bucket, 'ctr', type)
      expect(ctr.bucket_type).to eq name
    end
  end
end
