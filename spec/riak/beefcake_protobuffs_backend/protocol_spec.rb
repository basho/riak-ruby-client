require 'spec_helper'
require 'riak/client/beefcake/protocol'

describe Riak::Client::BeefcakeProtobuffsBackend::Protocol do
  let(:socket){ double 'Socket' }
  subject{ described_class.new socket }
  let(:codes){ Riak::Client::BeefcakeMessageCodes }

  describe 'writing messages' do
    # I really wanted to call this "send" but Ruby already has that method

    it 'writes messages without a body' do
      name = :PingReq

      socket.should_receive(:write) do |payload|
        length, code = payload.unpack 'NC'
        expect(length).to eq 1
        expect(code).to eq codes.index name
      end.ordered
      socket.should_receive(:flush).ordered

      subject.write name
    end

    it 'writes messages with Beefcake::Message instances as bodies' do
      message = yz_req
      name = :YokozunaSchemaGetReq

      socket.should_receive(:write) do |payload|
        header = payload[0..4]
        body = payload[5..-1]
        length, code = header.unpack 'NC'
        expect(code).to eq codes.index name
        expect(length).to eq(body.length + 1)
        expect(body).to eq message.encode.to_s
      end.ordered
      socket.should_receive(:flush).ordered

      subject.write name, message
    end
  end

  describe 'receiving messages' do
    it 'receives messages without a body and returns an array of code-symbol and nil' do
      name = :PingResp
      header = [1, codes.index(name)].pack 'NC'
      socket.should_receive(:read).
        ordered.
        with(5).
        and_return(header)

      code, payload = subject.receive

      expect(code).to eq name
      expect(payload).to eq nil
    end

    it 'receives messages and returns an array of code-symbol and string' do
      message = ctr_resp
      message_str = message.encode.to_s
      message_len = message_str.length
      name = :CounterGetResp
      header = [message_len + 1, codes.index(name)].pack 'NC'

      socket.should_receive(:read).
        ordered.
        with(5).
        and_return(header)
      socket.should_receive(:read).
        ordered.
        with(message_len).
        and_return(message_str)

      code, payload = subject.receive
      
      expect(code).to eq name
      expect(payload).to eq message_str
    end
  end

  describe 'expecting messages' do
    describe 'expected message received' do
      it 'accepts expected messages without a body and returns true' do
        name = :PingResp
        header = [1, codes.index(name)].pack 'NC'

        socket.should_receive(:read).
          with(5).
          and_return(header)

        payload = subject.expect name

        expect(payload).to eq true
      end

      it 'accepts expected messages and returns a Beefcake::Message instance' do
        message = ctr_resp
        message_str = message.encode.to_s
        message_len = message_str.length
        name = :CounterGetResp
        header = [message_len + 1, codes.index(name)].pack 'NC'
        
        socket.should_receive(:read).
          ordered.
          with(5).
          and_return(header)
        socket.should_receive(:read).
          ordered.
          with(message_len).
          and_return(message_str)
        
        payload = subject.expect name, message.class

        expect(payload).to eq message
        expect(payload.value).to eq message.value
      end

      it 'accepts messages with an empty body when required to' do
        name = :PutResp
        header = [1, codes.index(name)].pack 'NC'
        decoder_class = double 'RpbPutResp'

        socket.should_receive(:read).
          with(5).
          and_return(header)

        payload = subject.expect name, decoder_class, empty_body_acceptable: true

        expect(payload).to eq :empty
      end
    end

    describe 'unexpected message received' do
      it 'raises a ProtobuffsUnexpectedResponse error' do
        message = ctr_resp
        message_str = message.encode.to_s
        message_len = message_str.length
        name = :CounterGetResp
        header = [message_len + 1, codes.index(name)].pack 'NC'
        
        socket.should_receive(:read).
          ordered.
          with(5).
          and_return(header)
        socket.should_receive(:read).
          ordered.
          with(message_len).
          and_return(message_str)

        expect{ subject.expect :PingResp }.
          to raise_error Riak::ProtobuffsUnexpectedResponse
      end
    end

    describe 'ErrorResp received' do
      it 'raises a ProtobuffsErrorResponse error' do
        message = error_resp
        message_str = message.encode.to_s
        message_len = message_str.length
        name = :ErrorResp
        header = [message_len + 1, codes.index(name)].pack 'NC'
        
        socket.should_receive(:read).
          ordered.
          with(5).
          and_return(header)
        socket.should_receive(:read).
          ordered.
          with(message_len).
          and_return(message_str)

        expect{ subject.expect :PingResp }.
          to raise_error Riak::ProtobuffsErrorResponse
      end
    end
  end

  let(:yz_req){ Riak::Client::BeefcakeProtobuffsBackend::
    RpbYokozunaSchemaGetReq.new name: 'schema' }
  let(:ctr_resp){ Riak::Client::BeefcakeProtobuffsBackend::
    RpbCounterGetResp.new value: rand(2**10) }
  let(:error_resp){ Riak::Client::BeefcakeProtobuffsBackend::
    RpbErrorResp.new errcode: rand(2**10), errmsg: 'message' }
end
