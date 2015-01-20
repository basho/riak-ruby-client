require 'spec_helper'
Riak::Client::BeefcakeProtobuffsBackend.configured?

describe Riak::Client::BeefcakeProtobuffsBackend::BucketPropertiesOperator do
  let(:backend) { instance_double('Riak::Client::BeefcakeProtobuffsBackend') }
  
  let(:protocol) do
    instance_double('Riak::Client::BeefcakeProtobuffsBackend::Protocol').
      tap do |p|
      allow(backend).to receive(:protocol).and_yield(p)
    end
  end

  let(:bucket_name){ 'bucket_name' }
  let(:bucket) do
    instance_double('Riak::Bucket').tap do |b|
      allow(b).to receive(:name).and_return(bucket_name)
    end
  end

  let(:get_bucket_request) do
    { bucket: bucket_name }
  end
  
  let(:get_bucket_response) do
    props = Riak::Client::BeefcakeProtobuffsBackend::RpbBucketProps.
      new(
          n_val: 3,
          pr: 0xffffffff - 1,
          r: 0xffffffff - 2,
          w: 0xffffffff - 3,
          pw: 0xffffffff - 4,
          dw: 0,
          rw: 1
          )
    Riak::Client::BeefcakeProtobuffsBackend::RpbGetBucketResp.
      new(props: props)
  end
    
  subject{ described_class.new backend }

  it 'is initialized with a backend' do
    expect{ described_class.new backend }.to_not raise_error
  end

  it 'passes through scalar properties' do
    expect(protocol).to receive(:write).
      with(:GetBucketReq, get_bucket_request)

    expect(protocol).to receive(:expect).
      with(:GetBucketResp).
      and_return(get_bucket_response)

    resp = nil
    expect{ resp = subject.get bucket }.to_not raise_error

    expect(resp['n_val']).to eq 3
  end

  # "normalization" converts from riak naming to ruby-client naming
  # and quorums from strings into numbers

  describe 'quorums' do
    it 'normalizes' do
      expect(protocol).to receive(:write).
        with(:GetBucketReq, get_bucket_request)

      expect(protocol).to receive(:expect).
        with(:GetBucketResp).
        and_return(get_bucket_response)

      resp = nil
      expect{ resp = subject.get bucket }.to_not raise_error

      expect(resp['pr']).to eq 'one'
      expect(resp['r']).to eq 'quorum'
      expect(resp['w']).to eq 'all'
      expect(resp['pw']).to eq 'default'
      expect(resp['dw']).to eq 0
      expect(resp['rw']).to eq 1
    end

    it 'denormalizes'
  end

  describe 'commit hooks' do
    it 'normalizes modfuns'
    it 'denormalizes modfuns'

    it 'handles names'
  end

  describe 'modfuns' do
    it 'normalizes'
    it 'denormalizes'
  end

  describe 'repl modes' do
    it 'denormalizes symbols'
  end
end
