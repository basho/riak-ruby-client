require 'spec_helper'
require 'riak'

describe "Yokozuna", test_client: true, integration: true do
  before(:all) do
    @client = test_client

    @index = 'yz_spec-' + random_key
    @schema = 'yz_spec-' + random_key
  end

  context 'with no schema' do
    it 'should allow schema creation' do
      @client.create_search_schema(@schema, SCHEMA_CONTENT)
      wait_until{ !@client.get_search_schema(@schema).nil? }
      @client.get_search_schema(@schema).should_not be_nil
    end
  end
  context 'with a schema' do
    it 'should have a readable schema' do
      @client.create_search_schema(@schema, SCHEMA_CONTENT)
      wait_until{ !@client.get_search_schema(@schema).nil? }
      schema_resp = @client.get_search_schema(@schema)
      schema_resp.name.should == @schema
      schema_resp.content.should == SCHEMA_CONTENT
    end
  end

  SCHEMA_CONTENT = <<-XML
<?xml version=\"1.0\" encoding=\"UTF-8\" ?>
<schema name=\"#{@index}\" version=\"1.5\">
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

  def wait_until(attempts=5)
    begin
      break if yield rescue nil
      sleep 1
    end while (attempts -= 1) > 0
  end
end
