require 'spec_helper'
require_relative 'shared_examples'

describe Riak::Crdt::InnerCounter do
  let(:parent){ double 'parent' }
  let(:counter_name){ 'counter name' }
  subject do
    described_class.new(parent, 0).tap do |c|
      c.name = counter_name
    end
  end

  include_examples 'Counter CRDT'

  it 'should send increments to the parent' do
    parent.should_receive(:increment).
      with(counter_name, 1)

    subject.increment
  end
end
