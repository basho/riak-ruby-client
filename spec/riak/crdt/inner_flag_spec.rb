require 'spec_helper'

describe Riak::Crdt::InnerFlag do
  let(:parent){ double 'parent' }
  describe 'a truthy flag' do
    subject { described_class.new parent, true }

    it 'should feel truthy' do
      expect(subject).to be
    end
  end
  
  describe 'a falsey flag' do
    subject { described_class.new parent, false }

    it 'should feel falsey' do
      expect(subject).to_not be
    end
  end

  describe 'updating' do
    let(:new_value){ false }
    
    it 'should ask the class for an update operation' do
      operation = described_class.update(new_value)

      expect(operation.value).to eq new_value
      expect(operation.type).to eq :flag
    end
  end

  describe 'deleting' do
    it 'should ask the class for a delete operation' do
      operation = described_class.delete

      expect(operation.type).to eq :flag
    end
  end
end
