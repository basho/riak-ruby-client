describe Riak::Client::BeefcakeProtobuffsBackend::BucketPropertiesOperator do

  it 'is initialized with a backend'

  it 'passes through scalar properties' do
    expect(protocol).to receive(:write).
      with(:GetBucketReq, request)

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
        with(:GetBucketReq, request)

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
