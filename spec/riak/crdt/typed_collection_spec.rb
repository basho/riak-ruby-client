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
        
        it <<-EOD.gsub(/\s+/, ' ') do
          should ask the register class for an operation with the new value,
          add a name to it, and pass it up to the parent
          EOD
          register_class.should_receive(:update).
            with(new_value).
            and_return(operation)

          operation.
            should_receive(:name=).
            with('existing')

          parent.
            should_receive(:operate).
            with(operation)

          subject['existing'] = new_value
        end
      end

      describe 'removing' do
        let(:operation){ double 'operation' }

        it <<-EOD.gsub(/\s+/, ' ') do
          should ask the register class for a remove operation, add a name to
          it, and pass it up to the parent
          EOD
          register_class.
            should_receive(:delete).
            and_return(operation)

          operation.
            should_receive(:name=).
            with('existing')

          parent.
            should_receive(:operate).
            with(operation)

          subject.delete 'existing'
        end
      end
    end
    describe 'flags' do
      let(:flag_class){ Riak::Crdt::Flag }
      let(:operation){ double 'operation' }
      subject do
        described_class.new flag_class, parent, truthy: true, falsey: false
      end
      
      it 'should expose them as booleans' do
        expect(subject[:truthy]).to eq true
        expect(subject['falsey']).to eq false
      end

      it 'should update them' do
        flag_class.
          should_receive(:update).
          with(true).
          and_return(operation)

        operation.
          should_receive(:name=).
          with('become_truthy')

        parent.
          should_receive(:operate).
          with(operation)

        subject['become_truthy'] = true
      end
      
      it 'should delete them' do
        flag_class.
          should_receive(:delete).
          and_return(operation)

        operation.
          should_receive(:name=).
          with('become_deleted')

        parent.
          should_receive(:operate).
          with(operation)

        subject.delete 'become_deleted'
      end
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
