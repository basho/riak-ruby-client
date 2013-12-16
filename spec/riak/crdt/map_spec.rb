require 'spec_helper'
require_relative 'shared_examples'

describe Riak::Crdt::Map do
  let(:bucket) do
    double('bucket').tap do |b|
      b.stub(:name).and_return('bucket')
      b.stub(:is_a?).and_return(true)
      b.stub(:client).and_return(client)
    end
  end
  let(:operator){ double 'operator' }
  let(:loader){ double 'loader' }
  let(:backend){ double 'backend' }
  let(:client){ double 'client' }
  let(:key){ 'map' }
  
  before(:each) do
    client.stub(:backend).and_return(backend)
    backend.stub(:crdt_operator).and_return(operator)
    backend.stub(:crdt_loader).and_return(loader)
    loader.stub(:load).and_return({})
    loader.stub(:context).and_return('context')
  end
  
  subject{ described_class.new bucket, key }
  
  include_examples 'Map CRDT'

  describe 'batch mode' do
    it 'should queue up operations' do
      operator.
        should_receive(:operate) do |bucket, key_arg, type, operations|

        expect(bucket).to eq bucket
        expect(key_arg).to eq key
        expect(type).to eq Riak::Crdt::DEFAULT_MAP_BUCKET_TYPE

        expect(operations.first).to be_a Riak::Crdt::Operation::Update

        expect(operations.first.value).to be_a Riak::Crdt::Operation::Update
      end

      subject.batch do |s|
        s.registers['hello'] = 'hello'
        s.maps['goodbye'].flags['okay'] = true
      end
    end
  end

  describe 'immediate mode' do
    it 'should submit member operations immediately'
  end
end
