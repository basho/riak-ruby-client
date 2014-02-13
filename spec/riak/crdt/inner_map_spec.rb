require 'spec_helper'
require_relative 'shared_examples'

describe Riak::Crdt::InnerMap do
  let(:parent){ double 'parent' }
  subject{ described_class.new parent, {} }

  include_examples 'Map CRDT'

  let(:populated_contents) do
    {
      counters: {alpha: 0},
      flags: {bravo: true},
      maps: {},
      registers: {delta: 'the expendables' },
      sets: {echo: %w{stallone statham li lundgren}}      
    }
  end
  
  it 'should be initializable with a nested hash of maps' do
    expect{described_class.new parent, populated_contents}.
      to_not raise_error
  end

  describe 'deleting the inner map' do
    it 'should ask the class for a delete operation' do
      operation = described_class.delete

      expect(operation.type).to eq :map
    end
  end

  describe 'receiving an operation' do
    let(:inner_operation){ double 'inner operation' }
    it 'should wrap the operation in an update operation and pass it to the parent' do
      subject.name = 'name'
      
      parent.should_receive(:operate) do |name, op|
        expect(name).to eq 'name'
        expect(op.type).to eq :map
        expect(op.value).to eq inner_operation
      end
      
      subject.operate inner_operation
    end
  end
end
