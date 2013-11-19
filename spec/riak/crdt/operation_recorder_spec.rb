require 'spec_helper'

describe Riak::Crdt::OperationRecorder do
  let(:bucket){ double 'bucket', client: client }
  let(:client){ double 'client' }
  subject { described_class.new bucket, 'counter'}
  
  it 'should accept top-level operations' do
    expect{ subject.operate operation }.to_not raise_error
  end
  it 'should buffer operations' do
    
  end
  it 'should optimize multiple operations' do
    subject.operate
  end

  it 'should send send operations to a given CrdtOperator'
end
