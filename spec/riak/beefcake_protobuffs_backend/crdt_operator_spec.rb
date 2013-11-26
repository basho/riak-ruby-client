require 'spec_helper'
Riak::Client::BeefcakeProtobuffsBackend.configured?

describe Riak::Client::BeefcakeProtobuffsBackend::CrdtOperator do

  let(:backend_class){ Riak::Client::BeefcakeProtobuffsBackend }

  describe 'operating on a counter' do
    let(:key){ 'test_counter'}
    let(:backend){ double 'backend' }
    let(:client){ double 'client' }
    let(:bucket){ double 'bucket', name: 'counters', client: client }


    let(:increment){ 5 }
    let(:operation) do
      Riak::Crdt::Operation::Update.new.tap do |op|
        op.parent = double 'parent'
        op.name = nil
        op.type = :counter
        op.value = increment
      end
    end
    
    subject { described_class.new }
    
    it 'should serialize a counter operation into protobuffs' do
      result = subject.serialize operation

      expect(result).to be_a backend_class::DtOp
      expect(result.counter_op).to be
      expect(result.counter_op.increment).to eq increment
    end
  end

  describe 'operating on a map' do
    it 'should consume an OperationRecorder and serialize operations into protobuffs'
  end
end
