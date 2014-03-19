require 'spec_helper'
require 'riak/client/beefcake/protocol'

describe Riak::Client::BeefcakeProtobuffsBackend::Protocol do
  let(:socket){ double 'Socket' }
  subject{ described_class.new socket }
  describe 'writing messages' do
    # I really wanted to call this "send" but Ruby already has that method

    it 'writes messages without a body' do
      name = :PingReq

      socket.should_receive(:write) do |payload|
        length, code = payload.unpack 'NC'
        expect(length).to eq 1
        expect(code).to eq Riak::Client::BeefcakeMessageCodes.index name
      end.ordered
      socket.should_receive(:flush).ordered

      subject.write name
    end

    it 'writes messages with Beefcake::Message instances as bodies' do
      message = Riak::Client::BeefcakeProtobuffsBackend::
        RpbYokozunaSchemaGetReq.new name: 'schema'
      name = :YokozunaSchemaGetReq

      socket.should_receive(:write) do |payload|
        header = payload[0..4]
        body = payload[5..-1]
        length, code = header.unpack 'NC'
        expect(code).to eq Riak::Client::BeefcakeMessageCodes.index name
        expect(length).to eq(body.length + 1)
        expect(body).to eq message.encode.to_s
      end.ordered
      socket.should_receive(:flush).ordered

      subject.write name, message
    end
  end

  describe 'receiving messages' do
    it 'receives messages without a body'
    it 'receives messages and returns a Beefcake::Message instance'
  end

  describe 'expecting messages' do
    describe 'expected message received' do
      it 'accepts expected messages without a body'
      it 'accepts expected messages and returns a Beefcake::Message instance'
    end

    describe 'unexpected message received' do
      it 'raises a ProtobuffsUnexpectedResponse error'
    end

    describe 'ErrorResp received' do
      it 'raises a ProtobuffsErrorResponse error'
    end
  end
end
