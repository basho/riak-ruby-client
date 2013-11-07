require 'spec_helper'
require 'rexml/document'

describe "Search features" do
  describe Riak::Client do
    before :each do
      @client = Riak::Client.new
      @pb = mock(Riak::Client::BeefcakeProtobuffsBackend)
      @client.stub!(:backend).and_yield(@pb)
    end

    describe "searching" do
      it "should search the default index" do
        @pb.should_receive(:search).with(nil, "foo", {}).and_return({})
        @client.search("foo")
      end

      it "should search the default index with additional options" do
        @pb.should_receive(:search).with(nil, 'foo', 'rows' => 30).and_return({})
        @client.search("foo", 'rows' => 30)
      end

      it "should search the specified index" do
        @pb.should_receive(:search).with('search', 'foo', {}).and_return({})
        @client.search("search", "foo")
      end
    end
  end

  describe Riak::Bucket do
    before :each do
      @client = Riak::Client.new
      @bucket = Riak::Bucket.new(@client, "foo")
    end

    def load_without_index_hook
      @bucket.instance_variable_set(:@props, {"precommit" => [], "search" => false})
    end

    def load_with_index_hook
      @bucket.instance_variable_set(:@props, {"precommit" => [{"mod" => "riak_search_kv_hook", "fun" => "precommit"}], "search" => true})
    end

    it "should detect whether the indexing hook is installed" do
      load_without_index_hook
      @bucket.is_indexed?.should be_false

      load_with_index_hook
      @bucket.is_indexed?.should be_true
    end

    describe "enabling indexing" do
      it "should add the index hook when not present" do
        load_without_index_hook
        @bucket.should_receive(:props=).with({"precommit" => [Riak::Bucket::SEARCH_PRECOMMIT_HOOK], "search" => true})
        @bucket.enable_index!
      end

      it "should not modify the precommit when the hook is present" do
        load_with_index_hook
        @bucket.should_not_receive(:props=)
        @bucket.enable_index!
      end
    end

    describe "disabling indexing" do
      it "should remove the index hook when present" do
        load_with_index_hook
        @bucket.should_receive(:props=).with({"precommit" => [], "search" => false})
        @bucket.disable_index!
      end

      it "should not modify the precommit when the hook is missing" do
        load_without_index_hook
        @bucket.should_not_receive(:props=)
        @bucket.disable_index!
      end
    end
  end

  describe Riak::MapReduce do
    before :each do
      @client = Riak::Client.new
      @mr = Riak::MapReduce.new(@client)
    end

    describe "using a search query as inputs" do
      it "should accept a bucket name and query" do
        @mr.search("foo", "bar OR baz")
        @mr.inputs.should == {:module => "riak_search", :function => "mapred_search", :arg => ["foo", "bar OR baz"]}
      end

      it "should accept a Riak::Bucket and query" do
        @mr.search(Riak::Bucket.new(@client, "foo"), "bar OR baz")
        @mr.inputs.should == {:module => "riak_search", :function => "mapred_search", :arg => ["foo", "bar OR baz"]}
      end

      it "should emit the Erlang function and arguments" do
        @mr.search("foo", "bar OR baz")
        @mr.to_json.should include('"inputs":{')
        @mr.to_json.should include('"module":"riak_search"')
        @mr.to_json.should include('"function":"mapred_search"')
        @mr.to_json.should include('"arg":["foo","bar OR baz"]')
      end
    end
  end
end
