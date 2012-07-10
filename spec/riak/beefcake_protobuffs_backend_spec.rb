require 'spec_helper'

describe Riak::Client::BeefcakeProtobuffsBackend do
  before(:all) { described_class.should be_configured }
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

  context "#mapred" do
    let(:mapred) { Riak::MapReduce.new(client).add('test').map("function(){}") }

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
    before { backend.stub!(:decode_response) }

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
  end
end
