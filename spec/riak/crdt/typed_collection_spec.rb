require 'spec_helper'

describe Riak::Crdt::TypedCollection do
  describe 'initialization' do
    it "should accept a type"
    it "should accept a hash of values"
  end

  describe 'containing' do
    describe 'registers' do
      should 'expose them as strings'
      should 'update them'
    end
    describe 'flags' do
      should 'expose them as booleans'
      should 'update them'
    end
    describe 'counters' do
      should 'expose existing ones as Counter instances'
      should 'expose new ones as Counter instances'
      should 'allow incrementing and decrementing'
    end
    describe 'sets' do
      should 'expose existing ones as Set instances'
      should 'expose new ones as empty Set instances'
      should 'allow adding and removing'
    end
    describe 'maps' do
      should 'expose existing ones as populated Map instances'
      should 'expose new ones as empty Map instances'
      should 'cascade operations to a parent map'
    end
  end
end
