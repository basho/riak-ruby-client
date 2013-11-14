require 'spec_helper'

describe Riak::Crdt::Register do
  subject { described_class.new "espressos" }

  it 'should feel like a string' do
    expect{ subject.gsub('s', 'x')}.to_not raise_error
    expect(subject.gsub('s', 'x')).to eq('exprexxox')
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
end
