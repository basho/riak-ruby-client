require 'spec_helper'

describe Riak::Multiget do
  before :each do
    @client = Riak::Client.new
    @bucket = Riak::Bucket.new(@client, 'foo')
    @pairs = [[@bucket, 'key1'], [@bucket, 'key2']]
  end

  describe "initialization" do
    it "should accept a client and an array of bucket/key pairs" do
      lambda { Riak::Multiget.new(@client, @pairs) }.should_not raise_error
    end
  end

  describe "operation" do
    it "should fetch both keys from the bucket" do
      @bucket.should_receive(:[]).with('key1')
      @bucket.should_receive(:[]).with('key2')

      @multiget = Riak::Multiget.new(@client, @pairs)
      @multiget.fetch
      @multiget.wait_for_finish
    end

    it "should asynchronously fetch" do
      # make fetches slow
      @slow_mtx = Mutex.new
      @slow_mtx.lock

      # set up fetch process to wait on key2
      @bucket.should_receive(:[]) do |key|
        next if key == 'key1'

        # wait for test process
        @slow_mtx.lock
      end.twice

      # start fetch process
      @multiget = Riak::Multiget.new(@client, @pairs)
      @multiget.fetch

      @multiget.finished?.should be_false

      # allow fetch 
      @slow_mtx.unlock

      @results = @multiget.results
      @multiget.finished?.should be_true
      @results.should be_a Hash
    end
  end

  describe "results" do
    it "should return a hash of pairs to values" do
      @bucket.should_receive(:[]).with('key1')
      @bucket.should_receive(:[]).with('key2')
      
      @multiget = Riak::Multiget.new(@client, @pairs)
      @multiget.fetch
      @results = @multiget.results

      @results.should be_a Hash
    end
  end
end
