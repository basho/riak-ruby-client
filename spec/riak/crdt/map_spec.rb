require 'spec_helper'
require_relative 'shared_examples'

describe Riak::Crdt::Map do
  let(:client){ double 'client' }
  let(:bucket){ double 'bucket', client: client }
  subject{ described_class.new bucket, 'map' }
  
  include_examples 'Map CRDT'

  describe 'batch mode' do
    it 'should queue up operations'
    it 'should submit a queue of operations all at once'
  end

  describe 'immediate mode' do
    it 'should submit member operations immediately'
  end
end
