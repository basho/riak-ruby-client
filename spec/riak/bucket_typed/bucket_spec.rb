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
    expect(typed_robject.bucket.type).to eq type
  end

  it 'has a bucket type' do
    expect(subject.type).to eq type
    expect(subject.type.name).to eq 'type'
  end

  describe 'equality' do
    let(:same){ described_class.new client, name, type }
    let(:different){ described_class.new client, 'other', type }
    let(:untyped){ Riak::Bucket.new client, name }
    it { is_expected.to eq subject }
    it { is_expected.to eq same }
    it { is_expected.to_not eq untyped }
    it { is_expected.to_not eq different }
  end

  describe 'bucket properties' do
    it 'returns properties scoped by bucket and type' do
      expect(client).to receive(:get_bucket_props).
                         with(subject, { type: subject.type.name }).
                         and_return('allow_mult' => true)

      expect(props = subject.props).to be_a Hash
      expect(props['allow_mult']).to be
    end

    it 'clears properties scoped by bucket and type' do
      expect(client).to receive(:clear_bucket_props).
                         with(subject, { type: subject.type.name })

      expect{ subject.clear_props }.to_not raise_error
    end

    it 'sets properties scoped by bucket and type' do
      expect(client).to receive(:get_bucket_props).
                         with(subject, { type: subject.type.name }).
                         and_return('allow_mult' => false)
      expect(client).to receive(:set_bucket_props).
                         with(subject,
                              { 'allow_mult' => true },
                              subject.type.name)

     expect{ subject.props = { 'allow_mult' => true } }.to_not raise_error
    end
  end

  describe "querying an index" do
    it "attaches the bucket type" do
      expect(client).
        to receive(:get_index).
            with(subject, 'test_bin', 'testing', { type: 'type' }).
            and_return(
              Riak::IndexCollection.new_from_json({
                                                    keys: ['asdf']
                                                  }.to_json))

      result = subject.get_index('test_bin', 'testing')
      expect(result).to be_a Riak::IndexCollection
      expect(result.to_a).to eq %w{asdf}
    end
  end
end
