require 'spec_helper'

describe Riak::Crdt::TypedCollection do
  describe 'initialization' do
    it "should accept a type" do
      expect{ described_class.new Riak::Crdt::Counter }.to_not raise_error
    end
    it "should accept a hash of values" do
      expect{ described_class.new Riak::Crdt::Counter, {} }.to_not raise_error
    end
  end

  describe 'containing' do
    describe 'registers' do
      subject do
        described_class.new Riak::Crdt::Counter, existing: 'existing'
      end
      
      it 'should expose them as strings' do
        expect(subject[:existing]).to eq 'existing'
        expect(subject['existing']).to eq 'existing'
      end
      
      it 'should send a MapOp with an update to the parent on update'
      it 'should send a MapOp with an add and an update to the parent on create'
      it 'should send a MapOp with a remove on remove'
    end
    describe 'flags' do
      it 'should expose them as booleans'
      it 'should update them'
    end
    describe 'counters' do
      it 'should expose existing ones as Counter instances'
      it 'should expose new ones as Counter instances'
      it 'should allow incrementing and decrementing'
    end
    describe 'sets' do
      it 'should expose existing ones as Set instances'
      it 'should expose new ones as empty Set instances'
      it 'should allow adding and removing'
    end
    describe 'maps' do
      it 'should expose existing ones as populated Map instances'
      it 'should expose new ones as empty Map instances'
      it 'should cascade operations to a parent map'
    end
  end
end
