require 'spec_helper'

SingleCov.covered! uncovered: 3 if defined?(SingleCov)

describe Riak::Multiget do
  before :each do
    @client = Riak::Client.new
    @bucket = Riak::Bucket.new(@client, 'foo')
    @pairs = [[@bucket, 'key1'], [@bucket, 'key2']]
  end

  it "returns found objects when only some objects are found" do
    expect(@bucket).to receive(:[]).
      with('key1').
      and_raise(Riak::ProtobuffsFailedRequest.new(:not_found, "not found"))

    expect(@bucket).to receive(:[]).
      with('key2').
      and_return(true)

    results = Riak::Multiget.perform @client, @pairs

    expect(results[[@bucket, 'key1']]).to eq nil
    expect(results[[@bucket, 'key2']]).to eq true
  end

  it "fails when fetching the key produces an error" do
    expect(@bucket).to receive(:[]).
      with(satisfy { |key| %w(key1 key2).include?(key) }).
      and_raise(Riak::ProtobuffsFailedRequest.new(:whoops, "whoops")).
      at_least(1) # race condition ... both threads can read at the same time

    expect { Riak::Multiget.perform @client, @pairs }.to raise_error(Riak::ProtobuffsFailedRequest)
  end
end
