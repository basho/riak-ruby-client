require 'spec_helper'

describe Riak::Crdt::Counter do
  describe 'accessed directly' do
    it 'should be initialized with bucket, key, and optional bucket-type'
    it 'should be immediately incrementable'
    it 'should be batch-incrementable'
  end
  describe 'within a map' do
    it 'should be initializable with a parent'
    it 'should be initializable with an existing value'
    it 'should pass increments to its parent'
  end
end
