# encoding: UTF-8
require 'spec_helper'
require 'riak'

describe "Yokozona queries", riak: "2.0", test_client: true, integration: true do
  before :all do
    @client = test_client
  end

  context "with a schema and indexes" do
    before :all do
      @index = 'yz_spec-' + random_key

      @client.create_search_index(@index).should == true
      wait_until{ !@client.get_search_index(@index).nil? }
      @bucket = Riak::Bucket.new(@client, @index)
      @bucket.props = {'search_index' => @index}

      @o1 = build_json_obj(@bucket, "cat", {"cat_s"=>"Lela"})
      @o2 = build_json_obj(@bucket, "docs", {"dog_ss"=>["Einstein", "Olive"]})
      build_json_obj(@bucket, "Z", {"username_s"=>"Z", "name_s"=>"ryan", "age_i"=>30})
      build_json_obj(@bucket, "R", {"username_s"=>"R", "name_s"=>"eric", "age_i"=>34})
      build_json_obj(@bucket, "F", {"username_s"=>"F", "name_s"=>"bryan fink", "age_i"=>32})
      build_json_obj(@bucket, "H", {"username_s"=>"H", "name_s"=>"brett", "age_i"=>14})

      sleep 1.1  # pause for index commit to trigger
    end

    it "should produce results on single term queries" do
      resp = @client.search(@index, "username_s:Z")
      resp.should include('docs')
      resp['docs'].size.should == 1
    end

    it "should produce results on multiple term queries" do
      resp = @client.search(@index, "username_s:(F OR H)")
      resp.should include('docs')
      resp['docs'].size.should == 2
    end

    it "should produce results on queries with boolean logic" do
      resp = @client.search(@index, "username_s:Z AND name_s:ryan")
      resp.should include('docs')
      resp['docs'].size.should == 1
    end

    it "should produce results on range queries" do
      resp = @client.search(@index, "age_i:[30 TO 33]")
      resp.should include('docs')
      resp['docs'].size.should == 2
    end

    it "should produce results on phrase queries" do
      resp = @client.search(@index, 'name_s:"bryan fink"')
      resp.should include('docs')
      resp['docs'].size.should == 1
    end

    it "should produce results on wildcard queries" do
      resp = @client.search(@index, "name_s:*ryan*")
      resp.should include('docs')
      resp['docs'].size.should == 2
    end

    it "should produce results on regexp queries" do
      resp = @client.search(@index, "name_s:/br.*/")
      resp.should include('docs')
      resp['docs'].size.should == 2
    end

    # TODO: run this when pb utf8 works
    it "should support utf8" do
      build_json_obj(@bucket, "ja", {"text_ja"=>"私はハイビスカスを食べるのが 大好き"})
      # sleep 1.1  # pause for index commit to trigger
      # resp = @client.search(@index, "text_ja:大好き")
      # resp.should include('docs')
      # resp['docs'].size.should == 1
    end

    context "using parameters" do
      it "should search one row" do
        resp = @client.search(@index, "*:*", {:rows => 1})
        resp.should include('docs')
        resp['docs'].size.should == 1
      end

      it "should search with df" do
        resp = @client.search(@index, "Olive", {:rows => 1, :df => 'dog_ss'})
        resp.should include('docs')
        resp['docs'].size.should == 1
        resp['docs'].first['dog_ss']
      end

      it "should produce top result on sort" do
        resp = @client.search(@index, "username_s:*", {:sort => "age_i asc"})
        resp.should include('docs')
        resp['docs'].first['age_i'].to_i.should == 14
      end

    end
  end

  def wait_until(attempts=5)
    begin
      break if yield rescue nil
      sleep 1
    end while (attempts -= 1) > 0
  end

  # populate objects
  def build_json_obj(bucket, key, data)
    object = bucket.get_or_new(key)
    object.raw_data = data.to_json
    object.content_type = 'application/json'
    object.store
    object
  end
end
