require 'spec_helper'
require_relative 'shared_examples'

describe Riak::Crdt::InnerMap do
  let(:parent){ double 'parent' }
  subject{ described_class.new parent, {} }

  include_examples 'Map CRDT'
  
  describe 'updating the inner map' do
    it 'should ask the class for an update operation'
  end

  describe 'deleting the inner map' do
    it 'should ask the class for a delete operation'
  end

  describe 'receiving an operation' do
    it 'should wrap the operation in an update operation'
  end
end
