require 'spec_helper'
require 'riak'

describe "Yokozuna", test_client: true, integration: true do
  before(:all) do
    @client = test_client

    @index = 'yz_spec-' + random_key
    @schema = 'yz_spec-' + random_key
  end

  context "without any indexes" do
    it "should allow index creation" do
      @client.create_search_index(@index).should == true
    end
  end

  context "with an index" do
    before :all do
      @client.create_search_index(@index).should == true
      wait_until{ !@client.get_search_index(@index).nil? }
    end

    it "should allow index inspection" do
      @client.get_search_index(@index).name.should == @index
      lambda{ @client.get_search_index("herp_derp") }.should raise_error(Riak::ProtobuffsFailedRequest)
    end

    it "should have an index list" do
      @client.list_search_indexes.size.should >= 1
    end

    it "should associate a bucket with an index" do
      @bucket = Riak::Bucket.new(@client, @index)
      @bucket.props = {'search_index' => @index}
      @bucket = @client.bucket(@index)
      @bucket.props.should include('search_index' => @index)
    end

    context "associated with a bucket" do
      before :all do
        @bucket = Riak::Bucket.new(@client, @index)
        @bucket.props = {'search_index' => @index}
        @bucket = @client.bucket(@index)
        @bucket.props.should include('search_index' => @index)
      end

      it "should index on object writes" do
        object = @bucket.get_or_new("cat")
        object.raw_data = {"cat_s"=>"Lela"}.to_json
        object.content_type = 'application/json'
        object.store
        sleep 1.1  # pause for index commit to trigger

        resp = @client.search(@index, "cat_s:Lela")
        resp.should include('docs')
        resp['docs'].size.should == 1
      end
    end
  end

  def wait_until(attempts=5)
    begin
      break if yield rescue nil
      sleep 1
    end while (attempts -= 1) > 0
  end
end
