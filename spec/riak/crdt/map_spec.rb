require 'spec_helper'
require_relative 'shared_examples'

describe Riak::Crdt::Map do
  let(:bucket){ 'bucket' }
  subject{ described_class.new bucket, 'map' }
  
  include_examples 'Map CRDT'
end
