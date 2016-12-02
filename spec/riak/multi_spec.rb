require 'spec_helper'

SingleCov.covered! if defined?(SingleCov)

describe Riak::Multi do
  let(:multi) { Riak::Multi.new(@client, @pairs) }

  before :each do
    @client = Riak::Client.new
    @bucket = Riak::Bucket.new(@client, 'foo')
    @pairs = [[@bucket, 'key1'], [@bucket, 'key2']]
  end

  describe "#initialize" do
    it "fails on invalid bucket" do
      @pairs[0][0] = 'Opps'
      expect { multi }.to raise_error(ArgumentError)
    end

    it "fails on invalid key" do
      @pairs[0][1] = 123
      expect { multi }.to raise_error(ArgumentError)
    end
  end

  describe ".perform" do
    it "works" do
      expect_any_instance_of(Riak::Multi).to receive(:work).with(@bucket, 'key1')
      expect_any_instance_of(Riak::Multi).to receive(:work).with(@bucket, 'key2')
      expect(Riak::Multi.perform(@client, @pairs)).to eq([@bucket, 'key1'] => nil, [@bucket, 'key2'] => nil)
    end
  end

  describe "#perform" do
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

  describe "#finished?" do
    it "is not finished when not started" do
      expect(multi.finished?).to eq nil
    end

    it "is not finished when waiting" do
      multi.instance_variable_set(:@threads, [double(alive?: true)])
      expect(multi.finished?).to eq false
    end

    it "is finished when done" do
      multi.instance_variable_set(:@threads, [double(alive?: false)])
      expect(multi.finished?).to eq true
    end

    it "caches results for performance" do
      multi.instance_variable_set(:@threads, [double(alive?: false)])
      expect(multi.finished?).to eq true
      multi.instance_variable_set(:@threads, nil)
      expect(multi.finished?).to eq true
    end
  end

  describe "#results" do
    it "returns a hash of pairs to values" do
      expect(multi).to receive(:work).with(@bucket, 'key1')
      expect(multi).to receive(:work).with(@bucket, 'key2')

      multi.perform

      expect(multi.results).to be_a Hash
    end
  end

  describe "#work" do
    it "needs to be implemented in the subclasses" do
      expect { multi.send(:work, 1, 2) }.to raise_error(NotImplementedError)
    end
  end
end
