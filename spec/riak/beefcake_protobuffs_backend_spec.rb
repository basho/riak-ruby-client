require 'spec_helper'

describe Riak::Client::BeefcakeProtobuffsBackend do
  before(:all) { described_class.should be_configured }
  let(:client) { Riak::Client.new }
  let(:node) { client.nodes.first }
  let(:backend) { Riak::Client::BeefcakeProtobuffsBackend.new(client, node) }
  let(:protocol){ double 'protocol' }
  before(:each) do
    backend.stub(:get_server_version => "2.0.0")
    backend.stub(:protocol).and_yield(protocol)
  end

  context "secondary index" do
    before :each do
      @socket = double(:socket).as_null_object
      TCPSocket.stub(:new => @socket)
    end

    it 'should raise an appropriate error when 2i is not available' do
      protocol.should_receive(:write)
      protocol.should_receive(:expect).
        and_raise(
                  Riak::ProtobuffsErrorResponse.
                  new(Riak::Client::BeefcakeProtobuffsBackend::
                      RpbErrorResp.
                      new(errmsg: '{error,{indexes_not_supported,riak_kv_bitcask_backend}}',
                          errcode: 0)
                      )
                  )
      
      expect{ backend.get_index 'bucket', 'words', 'asdf' }.to raise_error /Secondary indexes aren't supported/
      # '
    end
    
    context 'when streaming' do
      it "should stream when a block is given" do 
        protocol.should_receive(:write) do |msg, req|
          msg.should == :IndexReq
          req[:stream].should == true
        end
        protocol.should_receive(:expect).
          and_return(Riak::Client::BeefcakeProtobuffsBackend::RpbIndexResp.new keys: %w{'asdf'}, done: true)

        blk = proc{:asdf}
        
        backend.get_index('bucket', 'words', 'asdf'..'hjkl', &blk)
      end

      it "should send batches of results to the block" do
        protocol.should_receive(:write)
        
        response_sets = [%w{asdf asdg asdh}, %w{gggg gggh gggi}]
        response_messages = response_sets.map do |s| 
          Riak::Client::BeefcakeProtobuffsBackend::RpbIndexResp.new keys: s
        end
        response_messages.last.done = true

        protocol.should_receive(:expect).and_return(*response_messages)

        block_body = double 'block'
        block_body.should_receive(:check).with(response_sets.first).once
        block_body.should_receive(:check).with(response_sets.last).once
        
        blk = proc {|m| block_body.check m }

        backend.get_index 'bucket', 'words', 'asdf'..'hjkl', &blk
      end
    end

    it "should return a full batch of results when not streaming" do
      protocol.should_receive(:write) do |msg, req|
        msg.should == :IndexReq
        req[:stream].should_not be
      end

      response_message = Riak::Client::BeefcakeProtobuffsBackend::
        RpbIndexResp.new(
                         keys: %w{asdf asdg asdh}
                         )
      protocol.should_receive(:expect).
        and_return(response_message)
      
      results = backend.get_index 'bucket', 'words', 'asdf'..'hjkl'
      results.should == %w{asdf asdg asdh}
    end

    it "should not crash out when no keys or terms are returned" do
      protocol.should_receive(:write) do |msg, req|
        msg.should == :IndexReq
        req[:stream].should_not be
      end

      response_message = Riak::Client::BeefcakeProtobuffsBackend::
        RpbIndexResp.new()

      protocol.should_receive(:expect).and_return(response_message)

      results = nil
      fetch = proc do
        results = backend.get_index 'bucket', 'words', 'asdf'
      end

      fetch.should_not raise_error
      results.should == []
    end
  end

  context "#mapred" do
    let(:mapred) { Riak::MapReduce.new(client).add('test').map("function(){}").map("function(){}") }

    it "should not return nil for previous phases that don't return anything" do
      protocol.should_receive(:write)

      message = double(:message, :phase => 1, :response => [{}].to_json)
      message.stub(:done).and_return(false, true)

      protocol.should_receive(:expect).
        twice.
        and_return(message)

      backend.mapred(mapred).should == [{}]
    end
  end

  context "preventing stale writes" do
    before { backend.stub(:decode_response => nil, :get_server_version => "1.0.3") }

    let(:robject) do
      Riak::RObject.new(client['stale'], 'prevent').tap do |obj|
        obj.prevent_stale_writes = true
        obj.raw_data = "stale"
        obj.content_type = "text/plain"
      end
    end

    it "should set the if_none_match field when the object is new" do
      protocol.should_receive(:write) do |msg, req|
        msg.should == :PutReq
        req.if_none_match.should be_true
      end
      protocol.should_receive(:expect).
        and_return(:empty)

      backend.store_object(robject)
    end

    it "should set the if_not_modified field when the object has a vclock" do
      robject.vclock = Base64.encode64("foo")
      protocol.should_receive(:write) do |msg, req|
        msg.should == :PutReq
        req.if_not_modified.should be_true
      end
      protocol.should_receive(:expect).
        and_return(:empty)
      backend.store_object(robject)
    end
  end
end
