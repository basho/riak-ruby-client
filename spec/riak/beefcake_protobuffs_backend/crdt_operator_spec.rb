require 'spec_helper'
Riak::Client::BeefcakeProtobuffsBackend.configured?

describe Riak::Client::BeefcakeProtobuffsBackend::CrdtOperator do

  let(:backend_class){ Riak::Client::BeefcakeProtobuffsBackend }
  let(:backend){ double 'beefcake protobuffs backend' }
  subject { described_class.new backend }

  
  describe 'operating on a counter' do
    let(:increment){ 5 }
    let(:operation) do
      Riak::Crdt::Operation::Update.new.tap do |op|
        op.type = :counter
        op.value = increment
      end
    end
    
    it 'serializes a counter operation into protobuffs' do
      result = subject.serialize operation
      
      expect(result).to be_a backend_class::DtOp
      expect(result.counter_op).to be_a backend_class::CounterOp
      expect(result.counter_op.increment).to eq increment
    end

    it 'serializes multiple counter operations into protobuffs' do
      result = subject.serialize [operation, operation]

      expect{result.encode}.to_not raise_error
      
      expect(result).to be_a backend_class::DtOp
      expect(result.counter_op).to be_a backend_class::CounterOp
      expect(result.counter_op.increment).to eq (increment * 2)
    end
  end

  describe 'operating on a set' do
    let(:added_element){ 'added_element' }
    let(:removed_element){ 'removed_element' }
    let(:operation) do
      Riak::Crdt::Operation::Update.new.tap do |op|
        op.type = :set
        op.value = {
          add: [added_element],
          remove: [removed_element]
        }
      end
    end

    it 'serializes a set operation into protobuffs' do
      result = subject.serialize operation

      expect{result.encode}.to_not raise_error
      
      expect(result).to be_a backend_class::DtOp
      expect(result.set_op).to be_a backend_class::SetOp
      expect(result.set_op.adds).to eq [added_element]
      expect(result.set_op.removes).to eq [removed_element]
    end
  end

  describe 'operating on a map' do
    it 'should serialize inner counter operations' do
      counter_op = Riak::Crdt::Operation::Update.new.tap do |op|
        op.name = 'inner_counter'
        op.type = :counter
        op.value = 12345
      end
      map_op = Riak::Crdt::Operation::Update.new.tap do |op|
        op.type = :map
        op.value = counter_op
      end

      result = subject.serialize map_op
      
      expect{result.encode}.to_not raise_error

      expect(result).to be_a backend_class::DtOp
      expect(result.map_op).to be_a backend_class::MapOp
      map_update = result.map_op.updates.first
      expect(map_update).to be_a backend_class::MapUpdate
      expect(map_update.counter_op).to be_a backend_class::CounterOp
      expect(map_update.counter_op.increment).to eq 12345
    end
    
    it 'should serialize inner flag operations' do
      flag_op = Riak::Crdt::Operation::Update.new.tap do |op|
        op.name = 'inner_flag'
        op.type = :flag
        op.value = true
      end
      map_op = Riak::Crdt::Operation::Update.new.tap do |op|
        op.type = :map
        op.value = flag_op
      end

      result = subject.serialize map_op

      expect{result.encode}.to_not raise_error

      expect(result).to be_a backend_class::DtOp
      expect(result.map_op).to be_a backend_class::MapOp
      map_update = result.map_op.updates.first
      expect(map_update).to be_a backend_class::MapUpdate
      expect(map_update.flag_op).to eq backend_class::MapUpdate::FlagOp::ENABLE

      flag_op = Riak::Crdt::Operation::Update.new.tap do |op|
        op.name = 'inner_flag'
        op.type = :flag
        op.value = false
      end
      map_op = Riak::Crdt::Operation::Update.new.tap do |op|
        op.type = :map
        op.value = flag_op
      end

      result = subject.serialize map_op

      expect{result.encode}.to_not raise_error

      expect(result).to be_a backend_class::DtOp
      expect(result.map_op).to be_a backend_class::MapOp
      map_update = result.map_op.updates.first
      expect(map_update).to be_a backend_class::MapUpdate
      expect(map_update.flag_op).to eq backend_class::MapUpdate::FlagOp::DISABLE
    end

    it 'should serialize inner register operations' do
      register_op = Riak::Crdt::Operation::Update.new.tap do |op|
        op.name = 'inner_register'
        op.type = :register
        op.value = 'hello'
      end
      map_op = Riak::Crdt::Operation::Update.new.tap do |op|
        op.type = :map
        op.value = register_op
      end

      result = subject.serialize map_op

      expect{result.encode}.to_not raise_error

      expect(result).to be_a backend_class::DtOp
      expect(result.map_op).to be_a backend_class::MapOp
      map_update = result.map_op.updates.first
      expect(map_update).to be_a backend_class::MapUpdate
      expect(map_update.register_op).to eq 'hello'

      delete_op = Riak::Crdt::Operation::Delete.new.tap do |op|
        op.name = 'inner_register'
        op.type = :register
      end
      map_op = Riak::Crdt::Operation::Update.new.tap do |op|
        op.type = :map
        op.value = delete_op
      end

      result = subject.serialize map_op

      expect{ result.encode }.to_not raise_error

      expect(result).to be_a backend_class::DtOp
      expect(result.map_op).to be_a backend_class::MapOp
      map_delete = result.map_op.removes.first
      expect(map_delete).to be_a backend_class::MapField
      expect(map_delete.name).to eq 'inner_register'
      expect(map_delete.type).to eq backend_class::MapField::MapFieldType::REGISTER
    end
    
    it 'should serialize inner set operations' do
      set_op = Riak::Crdt::Operation::Update.new.tap do |op|
        op.name = 'inner_set'
        op.type = :set
        op.value = {add: 'added_member'}
      end
      map_op = Riak::Crdt::Operation::Update.new.tap do |op|
        op.type = :map
        op.value = set_op
      end

      result = subject.serialize map_op

      expect{result.encode}.to_not raise_error

      expect(result).to be_a backend_class::DtOp
      expect(result.map_op).to be_a backend_class::MapOp
      map_update = result.map_op.updates.first
      expect(map_update).to be_a backend_class::MapUpdate
      expect(map_update.set_op.adds).to eq 'added_member'
    end
    
    it 'should serialize inner map operations' do
      register_op = Riak::Crdt::Operation::Update.new.tap do |op|
        op.name = 'inner_inner_register'
        op.type = :register
        op.value = 'inner_register_value'
      end
      inner_map_op = Riak::Crdt::Operation::Update.new.tap do |op|
        op.name = 'inner_map'
        op.type = :map
        op.value = register_op
      end
      map_op = Riak::Crdt::Operation::Update.new.tap do |op|
        op.type = :map
        op.value = inner_map_op
      end

      result = subject.serialize map_op

      expect{result.encode}.to_not raise_error

      expect(result).to be_a backend_class::DtOp
      expect(result.map_op).to be_a backend_class::MapOp
      map_update = result.map_op.updates.first
      expect(map_update).to be_a backend_class::MapUpdate
      expect(map_update.map_op).to be_a backend_class::MapOp
      expect(map_update.map_op.updates.first.register_op).to eq 'inner_register_value'
    end
  end
end
