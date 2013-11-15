require 'spec_helper'
require_relative 'shared_examples'

describe Riak::Crdt::InnerSet do
  let(:parent){ double 'parent' }
  let(:set_name){ 'set name' }
  subject do
    described_class.new(parent, []).tap do |s|
      s.name = set_name
    end
  end

  include_examples 'Set CRDT'

  it 'should send additions to the parent' do
    parent.should_receive(operate) do |op|
      expect(op.name).to eq set_name
      expect(op.type).to eq :set
      expect(op.value).to eq add: 'el'
    end

    subject.add 'el'

    parent.should_receive(operate) do |op|
      expect(op.name).to eq set_name
      expect(op.type).to eq :set
      expect(op.value).to eq remove: 'el2'
    end

    subject.remove 'el2'
  end
end
