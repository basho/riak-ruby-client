require 'spec_helper'

describe Riak::Client::BeefcakeProtobuffsBackend do
  before(:all) { expect(described_class).to be_configured }
  let(:client) { Riak::Client.new }
  let(:node) { client.nodes.first }
  let(:backend) { Riak::Client::BeefcakeProtobuffsBackend.new(client, node) }
  let(:protocol){ double 'protocol' }
  before(:each) do
    allow(backend).to receive(:get_server_version).and_return("2.0.0")
    allow(backend).to receive(:protocol).and_yield(protocol)
  end

  context "secondary index" do
    before :each do
      @socket = double(:socket).as_null_object
      allow(TCPSocket).to receive(:new).and_return(@socket)
    end

    it 'raises an appropriate error when 2i is not available' do
      expect(protocol).to receive(:write)
      expect(protocol).to receive(:expect).
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
      it "streams when a block is given" do
        expect(protocol).to receive(:write) do |msg, req|
          expect(msg).to eq(:IndexReq)
          expect(req[:stream]).to eq(true)
        end
        expect(protocol).to receive(:expect).
          and_return(Riak::Client::BeefcakeProtobuffsBackend::RpbIndexResp.new keys: %w{'asdf'}, done: true)

        blk = proc{:asdf}

        backend.get_index('bucket', 'words', 'asdf'..'hjkl', &blk)
      end

      it "sends batches of results to the block" do
        expect(protocol).to receive(:write)

        response_sets = [%w{asdf asdg asdh}, %w{gggg gggh gggi}]
        response_messages = response_sets.map do |s|
          Riak::Client::BeefcakeProtobuffsBackend::RpbIndexResp.new keys: s
        end
        response_messages.last.done = true

        expect(protocol).to receive(:expect).and_return(*response_messages)

        block_body = double 'block'
        expect(block_body).to receive(:check).with(response_sets.first).once
        expect(block_body).to receive(:check).with(response_sets.last).once

        blk = proc {|m| block_body.check m }

        backend.get_index 'bucket', 'words', 'asdf'..'hjkl', &blk
      end
    end

    it "returns a full batch of results when not streaming" do
      expect(protocol).to receive(:write) do |msg, req|
        expect(msg).to eq(:IndexReq)
        expect(req[:stream]).not_to be
      end

      response_message = Riak::Client::BeefcakeProtobuffsBackend::
        RpbIndexResp.new(
                         keys: %w{asdf asdg asdh}
                         )
      expect(protocol).to receive(:expect).
        and_return(response_message)

      results = backend.get_index 'bucket', 'words', 'asdf'..'hjkl'
      expect(results).to eq(%w{asdf asdg asdh})
    end

    it "returns no results when no keys or terms are returned" do
      expect(protocol).to receive(:write) do |msg, req|
        expect(msg).to eq(:IndexReq)
        expect(req[:stream]).not_to be
      end

      response_message = Riak::Client::BeefcakeProtobuffsBackend::
        RpbIndexResp.new()

      expect(protocol).to receive(:expect).and_return(response_message)

      results = nil
      fetch = proc do
        results = backend.get_index 'bucket', 'words', 'asdf'
      end

      expect(fetch).not_to raise_error
      expect(results).to eq([])
    end
  end

  context "#mapred" do
    let(:mapred) { Riak::MapReduce.new(client).add('test').map("function(){}").map("function(){}") }

    it "returns empty sets for previous phases that don't return anything" do
      expect(protocol).to receive(:write)

      message = double(:message, :phase => 1, :response => [{}].to_json)
      allow(message).to receive(:done).and_return(false, true)

      expect(protocol).to receive(:expect).
        twice.
        and_return(message)

      expect(backend.mapred(mapred)).to eq([{}])
    end
  end

  context "preventing stale writes" do
    before do
      allow(backend).to receive(:decode_response).and_return(nil)
      allow(backend).to receive(:get_server_version).and_return("1.0.3")
    end

    let(:robject) do
      Riak::RObject.new(client['stale'], 'prevent').tap do |obj|
        obj.prevent_stale_writes = true
        obj.raw_data = "stale"
        obj.content_type = "text/plain"
      end
    end

    it "sets the if_none_match field when the object is new" do
      expect(protocol).to receive(:write) do |msg, req|
        expect(msg).to eq(:PutReq)
        expect(req.if_none_match).to be_truthy
      end
      expect(protocol).to receive(:expect).
        and_return(:empty)

      backend.store_object(robject)
    end

    it "sets the if_not_modified field when the object has a vclock" do
      robject.vclock = Base64.encode64("foo")
      expect(protocol).to receive(:write) do |msg, req|
        expect(msg).to eq(:PutReq)
        expect(req.if_not_modified).to be_truthy
      end
      expect(protocol).to receive(:expect).
        and_return(:empty)
      backend.store_object(robject)
    end
  end
end
