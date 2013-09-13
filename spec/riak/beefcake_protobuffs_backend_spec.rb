require 'spec_helper'

describe Riak::Client::BeefcakeProtobuffsBackend do
  before(:all) { described_class.should be_configured }
  before(:each) { backend.stub(:get_server_version => "1.2.0") }
  let(:client) { Riak::Client.new }
  let(:node) { client.nodes.first }
  let(:backend) { Riak::Client::BeefcakeProtobuffsBackend.new(client, node) }

  it "should only write to the socket one time per request" do
    exp_bucket, exp_keys = 'foo', ['bar']
    mock_socket = mock("mock TCP socket")

    backend.stub!(:socket).and_return(mock_socket)
    mock_socket.should_receive(:write).exactly(1).with do |param|
      len, code = param[0,5].unpack("NC")
      req = Riak::Client::BeefcakeProtobuffsBackend::RpbListKeysReq.decode(param[5..-1])
      code == 17 && req.bucket == exp_bucket
    end

    responses = Array.new(2) do |index|
      resp = Riak::Client::BeefcakeProtobuffsBackend::RpbListKeysResp.new
      if index == 0
        resp.keys = exp_keys
      else
        resp.done = true
      end
      resp
    end

    responses.each do |response|
      encoded_response = response.encode
      mock_socket.should_receive(:read).exactly(1).with(5).and_return([1 + encoded_response.length, 18].pack("NC"))
      mock_socket.should_receive(:read).exactly(1).with(encoded_response.length).and_return(encoded_response)
    end

    backend.list_keys(exp_bucket).should == exp_keys
  end

  context "secondary index" do
    before :each do
      @socket = mock(:socket).as_null_object
      TCPSocket.stub(:new => @socket)
    end
    context 'when streaming' do
      it "should stream when a block is given" do 
        backend.should_receive(:write_protobuff) do |msg, req|
          msg.should == :IndexReq
          req[:stream].should == true
        end
        backend.should_receive(:decode_index_response)

        blk = proc{:asdf}
        
        backend.get_index('bucket', 'words', 'asdf'..'hjkl', &blk)
      end

      it "should send batches of results to the block" do
        backend.should_receive(:write_protobuff)
        
        response_sets = [%w{asdf asdg asdh}, %w{gggg gggh gggi}]
        response_messages = response_sets.map do |s| 
          Riak::Client::BeefcakeProtobuffsBackend::RpbIndexResp.new keys: s
        end
        response_messages.last.done = true

        response_chunks = response_messages.map do |m|
          encoded = m.encode
          header = [encoded.length + 1, 26].pack 'NC'
          [header, encoded]
        end.flatten

        @socket.should_receive(:read).and_return(*response_chunks)

        block_body = mock 'block'
        block_body.should_receive(:check).with(response_sets.first).once
        block_body.should_receive(:check).with(response_sets.last).once
        
        blk = proc {|m| block_body.check m }

        backend.get_index 'bucket', 'words', 'asdf'..'hjkl', &blk
      end
    end

    it "should return a full batch of results when not streaming" do
      backend.should_receive(:write_protobuff) do |msg, req|
        msg.should == :IndexReq
        req[:stream].should_not be
      end

      response_message = Riak::Client::BeefcakeProtobuffsBackend::
        RpbIndexResp.new(
                         keys: %w{asdf asdg asdh}
                         ).encode
      header = [response_message.length + 1, 26].pack 'NC'
      @socket.should_receive(:read).and_return(header, response_message)
      
      results = backend.get_index 'bucket', 'words', 'asdf'..'hjkl'
      results.should == %w{asdf asdg asdh}
    end

    it "should not crash out when no keys or terms are returned" do
      backend.should_receive(:write_protobuff) do |msg, req|
        msg.should == :IndexReq
        req[:stream].should_not be
      end

      response_message = Riak::Client::BeefcakeProtobuffsBackend::
        RpbIndexResp.new().encode

      header = [response_message.length + 1, 26].pack 'NC'
      @socket.
        should_receive(:read).
        with(5).
        and_return(header)

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
      socket = stub(:socket).as_null_object
      socket.stub(:read).and_return(stub(:socket_header, :unpack => [2, 24]), stub(:socket_message), stub(:socket_header_2, :unpack => [0, 1]))
      message = stub(:message, :phase => 1, :response => [{}].to_json)
      message.stub(:done).and_return(false, true)
      Riak::Client::BeefcakeProtobuffsBackend::RpbMapRedResp.stub(:decode => message)
      TCPSocket.stub(:new => socket)
      backend.send(:reset_socket)

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
      backend.should_receive(:write_protobuff) do |msg, req|
        msg.should == :PutReq
        req.if_none_match.should be_true
      end
      backend.store_object(robject)
    end

    it "should set the if_not_modified field when the object has a vclock" do
      robject.vclock = Base64.encode64("foo")
      backend.should_receive(:write_protobuff) do |msg, req|
        msg.should == :PutReq
        req.if_not_modified.should be_true
      end
      backend.store_object(robject)
    end

    context "when conditional requests are not supported" do
      before { backend.stub(:get_server_version => "0.14.2") }
      let(:other) { robject.dup.tap {|o| o.vclock = 'bar' } }

      it "should fetch the original object and raise if not equivalent" do
        robject.vclock = Base64.encode64("foo")
        backend.should_receive(:fetch_object).and_return(other)
        expect { backend.store_object(robject) }.to raise_error(Riak::FailedRequest)
      end
    end
  end
end
