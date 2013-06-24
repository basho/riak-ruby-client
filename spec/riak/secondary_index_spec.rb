require 'spec_helper'

describe Riak::SecondaryIndex do
  before(:each) do
    @client = Riak::Client.new
    @bucket = Riak::Bucket.new @client, 'foo'
  end
  describe "initialization" do
    it "should accept a bucket, index name, and scalar" do
      lambda { Riak::SecondaryIndex.new @bucket, 'asdf', 'aaaa' }.should_not raise_error
      lambda { Riak::SecondaryIndex.new @bucket, 'asdf', 12345 }.should_not raise_error
    end

    it "should accept a bucket, index name, and a range" do
      lambda { Riak::SecondaryIndex.new @bucket, 'asdf', 'aaaa'..'zzzz' }.should_not raise_error
      lambda { Riak::SecondaryIndex.new @bucket, 'asdf', 1..5 }.should_not raise_error
    end
  end

  describe "operation" do
    it "should return an array of keys"
    it "should return an array of values"
  end

  describe "streaming" do
    
  end
end
