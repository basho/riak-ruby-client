require 'spec_helper'
Riak::Client::BeefcakeProtobuffsBackend.configured?

describe Riak::Client::BeefcakeProtobuffsBackend::CrdtOperator do

  let(:backend_class){ Riak::Client::BeefcakeProtobuffsBackend }

  describe 'operating on a counter' do
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
      expect(result.counter_op).to be_a backend_class::CounterOp
      expect(result.counter_op.increment).to eq increment
    end
  end

  describe 'operating on a set' do
    let(:added_element){ 'added_element' }
    let(:removed_element){ 'removed_element' }
    let(:operation) do
      Riak::Crdt::Operation::Update.new.tap do |op|
        op.parent = double 'parent'
        op.name = nil
        op.type = :set
        op.value = {
          add: [added_element],
          remove: [removed_element]
        }
      end
    end

    it 'should serialize a set operation into protobuffs' do
      result = subject.serialize operation
      
      expect(result).to be_a backend_class::DtOp
      expect(result.set_op).to be_a backend_class::SetOp
      expect(result.set_op.adds).to eq [added_element]
      expect(result.set_op.removes).to eq [removed_element]
    end
  end

  describe 'operating on a map' do
    it 'should serialize inner counter operations' 
    it 'should serialize inner flag and register operations'
    it 'should serialize inner set operations'
    it 'should serialize inner map operations'
  end
end
