require 'spec_helper'

describe Riak::Crdt::Counter do
  describe 'accessed directly' do
    let(:bucket){ double 'bucket' }
    it 'should be initialized with bucket, key, and optional bucket-type' do
      expect{ described_class.new bucket, 'asdf' }.to_not raise_error
      expect{ described_class.new bucket, 'asdf', 'type' }.to_not raise_error
    end
    it 'should be immediately incrementable'
    it 'should be batch-incrementable'
  end
  describe 'within a map' do
    it 'should be initializable with a parent'
    it 'should be initializable with an existing value'
    it 'should pass increments to its parent'
  end
end
