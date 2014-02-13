require 'spec_helper'

describe Riak::Crdt::InnerRegister do
  let(:parent){ double 'parent' }
  subject { described_class.new parent, "espressos" }

  it 'should feel like a string' do
    expect(subject).to match 'espressos'
    expect{ subject.gsub('s', 'x') }.to_not raise_error
    expect(subject.gsub('s', 'x')).to eq 'exprexxox'
  end
  
  describe 'immutability' do
    it 'should be frozen' do
      expect(subject.frozen?).to be
    end
    it "shouldn't be gsub!-able" do
      # "gsub!-able" is awful, open to suggestions
      expect{ subject.gsub!('s', 'x') }.to raise_error
    end
  end

  describe 'updating' do
    let(:new_value){ 'new value' }
    it "should ask the class for an update operation" do
      operation = described_class.update(new_value)

      expect(operation.value).to eq new_value
      expect(operation.type).to eq :register
    end
  end

  describe 'deleting' do
    it 'should ask the class for a delete operation' do
      operation = described_class.delete

      expect(operation.type).to eq :register
    end
  end
end
