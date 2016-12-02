require 'spec_helper'

describe Riak::Multi do
  let(:multi) { Riak::Multi.new(@client, @pairs) }

  before :each do
    @client = Riak::Client.new
    @bucket = Riak::Bucket.new(@client, 'foo')
    @pairs = [[@bucket, 'key1'], [@bucket, 'key2']]
  end

  describe "initialization" do
    it "accepts a client and an array of bucket/key pairs" do
      expect { multi }.not_to raise_error
    end
  end

  describe "operation" do
    it "works on both keys from the bucket" do
      expect(multi).to receive(:work).with(@bucket, 'key1')
      expect(multi).to receive(:work).with(@bucket, 'key2')
      multi.perform
      multi.wait_for_finish
    end

    it "works asynchronously" do
      # make fetches slow
      slow_mtx = Mutex.new
      slow_mtx.lock

      # set up fetch process to wait on key2
      expect(multi).to receive(:work) { |_bucket, key|
        next if key == 'key1'

        # wait for test process
        slow_mtx.lock
      }.twice

      # start fetch process
      multi.perform

      expect(multi.finished?).to be_falsey

      # allow fetch
      slow_mtx.unlock

      results = multi.results
      expect(multi.finished?).to be_truthy
      expect(results).to be_a Hash
    end
  end

  describe "results" do
    it "returns a hash of pairs to values" do
      expect(multi).to receive(:work).with(@bucket, 'key1')
      expect(multi).to receive(:work).with(@bucket, 'key2')

      multi.perform

      expect(multi.results).to be_a Hash
    end
  end
end
