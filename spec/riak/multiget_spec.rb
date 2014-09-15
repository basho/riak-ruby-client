require 'spec_helper'

describe Riak::Multiget do
  before :each do
    @client = Riak::Client.new
    @bucket = Riak::Bucket.new(@client, 'foo')
    @pairs = [[@bucket, 'key1'], [@bucket, 'key2']]
  end

  describe "initialization" do
    it "accepts a client and an array of bucket/key pairs" do
      expect { Riak::Multiget.new(@client, @pairs) }.not_to raise_error
    end
  end

  describe "operation" do
    it "fetches both keys from the bucket" do
      expect(@bucket).to receive(:[]).with('key1')
      expect(@bucket).to receive(:[]).with('key2')

      @multiget = Riak::Multiget.new(@client, @pairs)
      @multiget.fetch
      @multiget.wait_for_finish
    end

    it "fetches asynchronously" do
      # make fetches slow
      @slow_mtx = Mutex.new
      @slow_mtx.lock

      # set up fetch process to wait on key2
      expect(@bucket).to receive(:[]) { |key|
        next if key == 'key1'

        # wait for test process
        @slow_mtx.lock
      }.twice

      # start fetch process
      @multiget = Riak::Multiget.new(@client, @pairs)
      @multiget.fetch

      expect(@multiget.finished?).to be_falsey

      # allow fetch 
      @slow_mtx.unlock

      @results = @multiget.results
      expect(@multiget.finished?).to be_truthy
      expect(@results).to be_a Hash
    end

    it "returns found objects when only some objects are found" do
      expect(@bucket).to receive(:[]).
        with('key1').
        and_raise(Riak::ProtobuffsFailedRequest.new(:not_found, "not found"))

      expect(@bucket).to receive(:[]).
        with('key2').
        and_return(true)

      @results = Riak::Multiget.get_all @client, @pairs

      expect(@results[[@bucket, 'key1']]).to be_nil
      expect(@results[[@bucket, 'key2']]).to be_truthy
    end
  end

  describe "results" do
    it "returns a hash of pairs to values" do
      expect(@bucket).to receive(:[]).with('key1')
      expect(@bucket).to receive(:[]).with('key2')
      
      @multiget = Riak::Multiget.new(@client, @pairs)
      @multiget.fetch
      @results = @multiget.results

      expect(@results).to be_a Hash
    end
  end
end
