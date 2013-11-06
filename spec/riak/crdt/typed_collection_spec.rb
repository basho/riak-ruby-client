require 'spec_helper'

describe Riak::Crdt::TypedCollection do
  before(:all) do
    backend.configured?
  end
  let(:parent){ double 'parent' }
  let(:backend){ Riak::Client::BeefcakeProtobuffsBackend }

  describe 'initialization' do
    it "should accept a type, parent, and hash of values" do
      expect{ described_class.new Riak::Crdt::Counter, parent, {} }.to_not raise_error
    end
  end

  describe 'containing' do
    describe 'registers' do
      let(:parent){ double 'parent' }
      subject do
        described_class.new Riak::Crdt::Register, parent, existing: 'existing'
      end
      
      it 'should expose them as strings' do
        expect(subject[:existing]).to eq 'existing'
        expect(subject['existing']).to eq 'existing'
      end
      
      it 'should send a MapOp with an update to the parent on update' do
        parent.should_receive(:backend_class).at_least(:once).and_return(backend)
        parent.should_receive(:update).with(instance_of(backend::MapOp))

        expect{subject['existing'] = 'new'}.to_not raise_error
      end
      
      it 'should send a MapOp with an add and an update to the parent on create' do
        parent.should_receive(:backend_class).at_least(:once).and_return(backend)
        parent.should_receive(:update).with(instance_of(backend::MapOp))

        expect{subject['actually_new'] = 'new'}.to_not raise_error
      end
      
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
