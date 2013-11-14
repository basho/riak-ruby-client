require 'spec_helper'

describe Riak::Crdt::TypedCollection do
  let(:parent){ double 'parent' }

  describe 'initialization' do
    it "should accept a type, parent, and hash of values" do
      expect{ described_class.new Riak::Crdt::Counter, parent, {} }.to_not raise_error
    end
  end

  describe 'containing' do
    describe 'registers' do
      let(:parent){ double 'parent' }
      let(:register_class){ Riak::Crdt::Register }
      subject do
        described_class.new register_class, parent, existing: 'existing'
      end
      
      it 'should expose them as frozen strings that are really Registers' do
        expect(subject[:existing]).to eq 'existing'
        expect(subject['existing']).to eq 'existing'
        expect(subject[:existing]).to be_an_instance_of register_class
        expect(subject['existing'].frozen?).to be
        expect{subject['existing'].gsub!('e', 'a')}.to raise_error
      end

      describe 'creating and updating' do

        let(:new_value){ 'the new value' }
        let(:operation){ double 'operation' }
        
        it 'should ask the register class for an operation with the new value' do

          register_class.should_receive(:update).
            with(new_value).
            and_return(operation)

          operation.
            should_receive(:name=).
            with('existing')

          parent.should_receive(:operate)

          subject['existing'] = new_value
        end
        
        it 'should give a named operation to the parent' do
          parent.should_receive(:operate) do |op|
            pp op
            expect(op.name).to eq 'existing'
            expect(op.value).to eq new_value
            expect(op.parent).to_not be
          end

          subject['existing'] = new_value
        end
      end
      
      it 'should send an Operation with an update to the parent on update'
      it 'should send an Operation with an update to the parent on create'    
      it 'should send an Operation with a remove on remove'
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
