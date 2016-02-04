require 'spec_helper'
require 'riak/client/beefcake/object_methods'
require 'riak/client/beefcake/messages'

describe Riak::Client::BeefcakeProtobuffsBackend::ObjectMethods do
  before :each do
    @client = Riak::Client.new
    @backend = Riak::Client::BeefcakeProtobuffsBackend.new(@client, @client.node)
    @bucket = Riak::Bucket.new(@client, "bucket")
    @object = Riak::RObject.new(@bucket, "bar")
    @content = double(
      :value => '',
      :vtag => nil,
      :content_type => nil,
      :content_encoding => nil,
      :links => nil,
      :usermeta => nil,
      :last_mod => nil,
      :last_mod_usecs => nil,
      :indexes => nil,
      :charset => nil
    )
  end

  describe "loading object data from the response" do
    it "loads the key" do
      pbuf = double(:vclock => nil, :content => [@content], :value => nil, :key => 'akey')
      o = @backend.load_object(pbuf, @object)
      expect(o).to eq(@object)
      expect(o.key).to eq(pbuf.key)
    end

    describe "last_modified" do
      before :each do
        allow(@content).to receive(:last_mod) { 1271442363 }
      end

      it "is set to time of last_mod with microseconds from last_mod_usecs" do
        allow(@content).to receive(:last_mod_usecs) { 105696 }
        pbuf = double(:vclock => nil, :content => [@content], :value => nil, :key => 'akey')
        o = @backend.load_object(pbuf, @object)
        expect(o.last_modified).to eq(Time.at(1271442363, 105696))
      end

      it "is set to time of last_mod without microseconds if last_mod_usecs is missing" do
        pbuf = double(:vclock => nil, :content => [@content], :value => nil, :key => 'akey')
        o = @backend.load_object(pbuf, @object)
        expect(o.last_modified).to eq(Time.at(1271442363, 0))
      end
    end
  end

end
