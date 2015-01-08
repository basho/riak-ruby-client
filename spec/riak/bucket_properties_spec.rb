describe Riak::BucketProperties do
  let(:client){ instance_double 'Riak::Client' }
  let(:backend) do
    instance_double('Riak::Client::BeefcakeProtobuffsBackend').tap do |be|
      allow(client).to receive(:backend).and_yield be
    end
  end

  it 'is initialized with a client and bucket' do
    p = nil
    expect{ p = described_class.new client, bucket }.to_not raise_error
    expect(p.client).to eq client
    expect(p.bucket).to eq bucket
  end

  it 'initialzies correctly with a bucket-typed bucket' do
    p = nil
    expect{ p = described_class.new client, typed_bucket }.to_not raise_error
    expect(p.client).to eq client
    expect(p.bucket).to eq typed_bucket
  end

  it 'provides hash-like access to properties' do
    expect(backend).to receive(:get_bucket_props).
      with(bucket).
      and_return('allow_mult' => true)

    expect(subject['allow_mult']).to be

    subject['allow_mult'] = false

    expect(backend).to receive(:set_bucket_props).
      with(bucket, hash_including(allow_mult: false))

    subject.store
  end

  it 'merges properties from hashes'
  it 'merges properties from other bucket properties objects'

  it 'reloads'
  it 'stores'
end
