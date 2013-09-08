# require 'spec_helper'
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib'))

require 'rubygems' # Use the gems path only for the spec suite
require 'riak'
require 'rspec'

RSpec.configure do |c|
  # declare an exclusion filter
  @http_port ||= 10018 # test_server.http_port
  @client = Riak::Client.new(:http_port => @http_port)
  yz_active = @client.ping rescue false
  c.filter_run_excluding :yokozuna => !yz_active
end

describe "Yokozuna", :yokozuna => true do
  before(:all) do
    @pbc_port ||= 10017  # test_server.pb_port
    @http_port ||= 10018 # test_server.http_port
    @client = Riak::Client.new(:http_port => @http_port, :pb_port => @pbc_port, :protocol => "pbc")

    @index = "test"
    @schema = "testschema"
  end

  context "using the admin client" do
    it "should create / get / list indexes" do
      @client.create_search_index(@index).should == true
      # TODO: replace this with a wait function
      sleep 1.1
      @client.get_search_index(@index).name.should == @index
      @client.list_search_indexes.size.should >= 1 
      lambda{ @client.get_search_index("herp_derp") }.should raise_error(Riak::ProtobuffsFailedRequest)
    end

    it "should associate a bucket with an index" do
      @bucket = Riak::Bucket.new(@client, @index)
      @bucket.props = {'yz_index' => @index}
      @bucket = @client.bucket(@index)
      @bucket.props.should include('yz_index' => @index)
    end

    it "should create / get schemas" do
      content = <<-XML
<?xml version=\"1.0\" encoding=\"UTF-8\" ?>
<schema name=\"test\" version=\"1.5\">
<fields>
   <field name=\"_yz_id\" type=\"_yz_str\" indexed=\"true\" stored=\"true\" required=\"true\" />
   <field name=\"_yz_ed\" type=\"_yz_str\" indexed=\"true\" stored=\"true\"/>
   <field name=\"_yz_pn\" type=\"_yz_str\" indexed=\"true\" stored=\"true\"/>
   <field name=\"_yz_fpn\" type=\"_yz_str\" indexed=\"true\" stored=\"true\"/>
   <field name=\"_yz_vtag\" type=\"_yz_str\" indexed=\"true\" stored=\"true\"/>
   <field name=\"_yz_node\" type=\"_yz_str\" indexed=\"true\" stored=\"true\"/>
   <field name=\"_yz_rk\" type=\"_yz_str\" indexed=\"true\" stored=\"true\"/>
   <field name=\"_yz_rb\" type=\"_yz_str\" indexed=\"true\" stored=\"true\"/>
</fields>
<uniqueKey>_yz_id</uniqueKey>
<types>
    <fieldType name=\"_yz_str\" class=\"solr.StrField\" sortMissingLast=\"true\" />
</types>
</schema>
      XML
      @client.create_search_schema(@schema, content)
      schema_resp = @client.get_search_schema(@schema)
      schema_resp.name.should == @schema
      schema_resp.content.should == content
    end
  end

  context "using the search client" do
    before(:all) do
      @bucket = @client.bucket(@index)

      @object = @bucket.get_or_new("cat")
      @object.raw_data = '{"cat_s":"Lela"}'
      @object.content_type = 'application/json'
      @object.store

      @object2 = @bucket.get_or_new("dogs")
      @object2.raw_data = '{"dog_ss":["Einstein", "Olive"]}'
      @object2.content_type = 'application/json'
      @object2.store

      sleep 1.1
    end

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
  end

  # context "using the HTTP driver" do
  #   it "should search as XML" do
  #     resp = @http_client.search("test", "*:*", {:rows => 1, :wt => 'xml'})
  #     root = REXML::Document.new(resp).root
  #     root.name.should == 'response'
  #     doc = root.elements['result'].elements['doc']
  #     doc.should_not be_nil
  #     cats = doc.elements["str[@name='cat_s']"]
  #     cats.should have(1).item
  #     cats.text.should == 'Lela'
  #   end
  #   it "should search as JSON with df" do
  #     resp = @http_client.search("test", "Olive", {:rows => 1, :wt => 'json', :df => 'dog_ss'})
  #   end
  # end

  after(:all) do
    # Can't delete index with associate buckets
    lambda{ @client.delete_search_index(@index) }.should raise_error(Riak::ProtobuffsFailedRequest)

    # disassociate
    @bucket = @client.bucket(@index)
    @bucket.props = {'yz_index' => nil}

    @client.delete_search_index(@index)
  end
end