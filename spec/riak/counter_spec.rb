require 'spec_helper'

describe Riak::Counter do
  describe "initialization" do
    before :each do
      @bucket = mock 'bucket'
      @key = 'key'
      @bucket.stub allow_mult: true
      @bucket.stub(client: mock('client'))
    end

    it "should set the bucket and key" do
      ctr = Riak::Counter.new @bucket, @key
      ctr.bucket.should == @bucket
      ctr.key.should == @key
    end

    it "should require allow_mult" do
      @bad_bucket = mock 'bad bucket'
      @bad_bucket.stub allow_mult: false
      @bad_bucket.stub(client: mock('client'))

      expect{ctr = Riak::Counter.new @bad_bucket, @key}.to raise_error(ArgumentError)
      
    end
  end
  
  describe "incrementing and decrementing" do
    before :each do
      @backend = mock 'backend'

      @client = mock 'client'
      @client.stub(:http).and_yield @backend

      @bucket = mock 'bucket'
      @bucket.stub allow_mult: true
      @bucket.stub client: @client

      @key = 'key'

      @ctr = Riak::Counter.new @bucket, @key

      @increment_expectation = proc{|n| @backend.should_receive(:post_counter).with(@bucket, @key, n)}
    end

    it "should increment by 1 by default" do
      @increment_expectation[1]
      @ctr.increment
    end

    it "should support incrementing by positive numbers" do
      @increment_expectation[15]
      @ctr.increment 15
    end

    it "should support incrementing by negative numbers" do
      @increment_expectation[-12]
      @ctr.increment -12
    end

    it "should decrement by 1 by default" do
      @increment_expectation[-1]
      @ctr.decrement
    end

    it "should support decrementing by positive numbers" do
      @increment_expectation[-30]
      @ctr.decrement 30
    end

    it "should support decrementing by negative numbers" do
      @increment_expectation[41]
      @ctr.decrement -41
    end

    it "should forbid incrementing by non-integers" do
      [1.1, nil, :'1', '1', 2.0/2, [1]].each do |candidate|
        expect do
          @ctr.increment candidate
          raise candidate.to_s
        end.to raise_error(ArgumentError)
      end
    end
  end

  describe "failure modes" do
    it "should not retry on timeout"
    it "should not retry on quorum failure"
  end
end
