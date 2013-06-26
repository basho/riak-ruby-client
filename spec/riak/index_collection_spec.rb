require 'spec_helper'

describe Riak::IndexCollection do
  describe "json initialization" do
    it "should accept a list of keys" do
      @input = {
        'keys' => %w{first second third}
      }.to_json
      lambda { @coll = Riak::IndexCollection.new @input }.should_not raise_error
      %w{first second third}.should == @coll
    end
    it "should accept a list of keys and a continuation" do
      @input = {
        'keys' => %w{first second third},
        'continuation' => 'examplecontinuation'
      }.to_json
      lambda { @coll = Riak::IndexCollection.new @input }.should_not raise_error
      %w{first second third}.should == @coll
      @coll.continuation.should == 'examplecontinuation'
    end
    it "should accept a list of results hashes" do
      @input = {
        'results' => [
          {'first' => 'first'},
          {'second' => 'second'},
          {'second' => 'other'}
        ]
      }.to_json

      lambda { @coll = Riak::IndexCollection.new @input }.should_not raise_error
      %w{first second other}.should == @coll
      {'first' => %w{first}, 'second' => %w{second other}}.should == @coll.with_terms
    end
    it "should accept a list of results hashes and a continuation" do
      @input = {
        'results' => [
          {'first' => 'first'},
          {'second' => 'second'},
          {'second' => 'other'}
        ],
        'continuation' => 'examplecontinuation'
      }.to_json

      lambda { @coll = Riak::IndexCollection.new @input }.should_not raise_error
      %w{first second other}.should == @coll
      @coll.continuation.should == 'examplecontinuation'
      {'first' => %w{first}, 'second' => %w{second other}}.should == @coll.with_terms
    end
  end
end
