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
    expect(typed_robject.key).to eq 'panther'
    expect(typed_robject.type).to eq type
  end

  it 'has a bucket type' do
    expect(subject.type).to eq type
    expect(subject.type.name).to eq 'type'
  end

  describe 'bucket properties' do
    it 'returns properties scoped by bucket and type' do
      expect(client).to receive(:get_bucket_props).with(subject, { type: subject.type.name }).and_return('allow_mult' => true)

      expect(props = subject.props).to be_a Hash
      expect(props['allow_mult']).to be
    end

    it 'clears properties scoped by bucket and type' do
      expect(client).to receive(:clear_bucket_props).with(subject, { type: subject.type.name })

      expect{ subject.clear_props }.to_not raise_error
    end

    it 'sets properties scoped by bucket and type' do
      expect(client).to receive(:set_bucket_props).with(subject, { 'allow_mult' => true }, subject.type.name)

     expect{ subject.props = { 'allow_mult' => true } }.to_not raise_error
    end
  end
end
