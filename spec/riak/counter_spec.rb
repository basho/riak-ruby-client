require 'spec_helper'

describe Riak::Counter do
  describe "initialization" do
    before :each do
      @bucket = mock 'bucket'
      @key = 'key'
      @bucket.stub allow_mult: true
    end

    it "should set the bucket and key" do
      ctr = Riak::Counter.new @bucket, @key
      ctr.bucket.should == @bucket
      ctr.key.should == @key
    end

    it "should require allow_mult" do
      @bad_bucket = mock 'bad bucket'
      @bad_bucket.stub allow_mult: false

      expect{ctr = Riak::Counter.new @bad_bucket, @key}.to raise_error(ArgumentError)
      
    end
    it "should require http"
  end
  
  describe "incrementing and decrementing" do
    before :each do
      @bucket = mock 'bucket'
      @key = 'key'
      @bucket.stub allow_mult: true
      @ctr = Riak::Counter.new @bucket, @key
    end

    it "should increment by 1 by default"
    it "should support incrementing by positive numbers"
    it "should support incrementing by negative numbers"

    it "should decrement by 1 by default"
    it "should support decrementing by positive numbers"
    it "should support decrementing by negative numbers"

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
