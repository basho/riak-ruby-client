require 'spec_helper'

describe Riak::IndexCollection do
  describe "json initialization" do
    it "accepts a list of keys" do
      @input = {
        'keys' => %w{first second third}
      }.to_json
      expect { @coll = Riak::IndexCollection.new_from_json @input }.not_to raise_error
      expect(%w{first second third}).to eq(@coll)
    end

    it "accepts a list of keys and a continuation" do
      @input = {
        'keys' => %w{first second third},
        'continuation' => 'examplecontinuation'
      }.to_json
      expect { @coll = Riak::IndexCollection.new_from_json @input }.not_to raise_error
      expect(%w{first second third}).to eq(@coll)
      expect(@coll.continuation).to eq('examplecontinuation')
    end

    it "accepts a list of results hashes" do
      @input = {
        'results' => [
          {'first' => 'first'},
          {'second' => 'second'},
          {'second' => 'other'}
        ]
      }.to_json

      expect { @coll = Riak::IndexCollection.new_from_json @input }.not_to raise_error
      expect(%w{first second other}).to eq(@coll)
      expect({'first' => %w{first}, 'second' => %w{second other}}).to eq(@coll.with_terms)
    end

    it "accepts a list of results hashes and a continuation" do
      @input = {
        'results' => [
          {'first' => 'first'},
          {'second' => 'second'},
          {'second' => 'other'}
        ],
        'continuation' => 'examplecontinuation'
      }.to_json

      expect { @coll = Riak::IndexCollection.new_from_json @input }.not_to raise_error
      expect(%w{first second other}).to eq(@coll)
      expect(@coll.continuation).to eq('examplecontinuation')
      expect({'first' => %w{first}, 'second' => %w{second other}}).to eq(@coll.with_terms)
    end
  end
end
