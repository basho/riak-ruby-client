require 'spec_helper'

describe Riak::Multiexist do
  before :each do
    @client = Riak::Client.new
    @bucket = Riak::Bucket.new(@client, 'foo')
    @pairs = [[@bucket, 'key1'], [@bucket, 'key2']]
  end

  it "returns state when only some objects are found" do
    expect(@bucket).to receive(:exists?).
      with('key1').
      and_return(false)

    expect(@bucket).to receive(:exists?).
      with('key2').
      and_return(true)

    results = Riak::Multiexist.perform @client, @pairs

    expect(results[[@bucket, 'key1']]).to eq false
    expect(results[[@bucket, 'key2']]).to eq true
  end

  it "fails when checking the key produces an error" do
    expect(@bucket).to receive(:exists?).
      with(satisfy { |key| %w(key1 key2).include?(key) }).
      and_raise(Riak::ProtobuffsFailedRequest.new(:whoops, "whoops")).
      at_least(1) # race condition ... both threads can read at the same time

    expect { Riak::Multiexist.perform @client, @pairs }.to raise_error(Riak::ProtobuffsFailedRequest)
  end
end
