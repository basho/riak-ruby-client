require 'spec_helper'
require_relative 'shared_examples'

describe Riak::Crdt::Counter do
  let(:bucket){ double 'bucket' }
  it 'should be initialized with bucket, key, and optional bucket-type' do
    expect{ described_class.new bucket, 'asdf' }.to_not raise_error
    expect{ described_class.new bucket, 'asdf', 'type' }.to_not raise_error
  end

  subject{ described_class.new bucket, 'asdf' }

  describe 'with a client' do
    let(:backend){ double 'backend' }
    let(:client){ double 'client', backend: backend }
    before(:each) do
      bucket.stub(:client, client)
    end
    
    include_examples 'Counter CRDT'
  end
end
