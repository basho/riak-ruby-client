require 'spec_helper'
require 'riak'

describe "Yokozona queries", test_server: true, integration: true do
  before :all do
    opts = {
      http_port: test_server.http_port,
      pb_port: test_server.pb_port,
      protocol: 'pbc'
    }
    test_server.start
    @client = Riak::Client.new opts
  end

  context "with a schema and indexes" do
    before :all do
      @index = "test"

      @client.create_search_index(@index).should == true
      sleep 1.1  # wait for index to load
      @bucket = Riak::Bucket.new(@client, @index)
      @bucket.props = {'yz_index' => @index}

      # populate objects
      def build_json_obj(key, data)
        object = @bucket.get_or_new(key)
        object.raw_data = data.to_json
        object.content_type = 'application/json'
        object.store
        object
      end

      @o1 = build_json_obj("cat", {"cat_s"=>"Lela"})
      @o2 = build_json_obj("docs", {"dog_ss"=>["Einstein", "Olive"]})
      build_json_obj("Z", {"username_s"=>"Z", "name_s"=>"ryan", "age_i"=>30})
      build_json_obj("R", {"username_s"=>"R", "name_s"=>"eric", "age_i"=>34})
      build_json_obj("F", {"username_s"=>"F", "name_s"=>"bryan fink", "age_i"=>32})
      build_json_obj("H", {"username_s"=>"H", "name_s"=>"brett", "age_i"=>14})

      sleep 1.1  # pause for index commit to trigger
    end

    it "should produce results on single term queries" do
      resp = @client.search("test", "username_s:Z")
      resp.should include('docs')
      resp['docs'].size.should == 1
    end

    it "should produce results on multiple term queries" do
      resp = @client.search("test", "username_s:(F OR H)")
      resp.should include('docs')
      resp['docs'].size.should == 2
    end

    it "should produce results on queries with boolean logic" do
      resp = @client.search("test", "username_s:Z AND name_s:ryan")
      resp.should include('docs')
      resp['docs'].size.should == 1
    end

    it "should produce results on range queries" do
      resp = @client.search("test", "age_i:[30 TO 33]")
      resp.should include('docs')
      resp['docs'].size.should == 2
    end

    it "should produce results on phrase queries" do
      resp = @client.search("test", 'name_s:"bryan fink"')
      resp.should include('docs')
      resp['docs'].size.should == 1
    end

    it "should produce results on wildcard queries" do
      resp = @client.search("test", "name_s:*ryan*")
      resp.should include('docs')
      resp['docs'].size.should == 2
    end

    it "should produce results on regexp queries" do
      resp = @client.search("test", "name_s:/br.*/")
      resp.should include('docs')
      resp['docs'].size.should == 2
    end

    context "using parameters" do
      it "should search one row" do
        resp = @client.search("test", "*:*", {:rows => 1})
        resp.should include('docs')
        resp['docs'].size.should == 1
      end

      it "should search with df" do
        resp = @client.search("test", "Olive", {:rows => 1, :df => 'dog_ss'})
        resp.should include('docs')
        resp['docs'].size.should == 1
        resp['docs'].first['dog_ss']
      end

      it "should produce top result on sort" do
        resp = @client.search("test", "username_s:*", {:sort => "age_i asc"})
        resp.should include('docs')
        resp['docs'].first['age_i'].to_i.should == 14
      end

    end

    after(:all) do
      # Can't delete index with associate buckets
      lambda{ @client.delete_search_index(@index) }.should raise_error(Riak::ProtobuffsFailedRequest)

      # disassociate
      @bucket = @client.bucket(@index)
      @bucket.props = {'yz_index' => nil}

      @client.delete_search_index(@index)
    end
  end
end
