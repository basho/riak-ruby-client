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
  let(:backend){ double 'backend' }
  let(:client){ double 'client' }

  before(:each) do
    client.stub(:backend).and_return(backend)
    backend.stub(:crdt_operator).and_return(operator)
  end
  
  subject{ described_class.new bucket, 'map' }
  
  include_examples 'Map CRDT'

  describe 'batch mode' do
    it 'should queue up operations' do
      operator.
        should_receive(:operate) do |bucket, key, type, operations|

        expect(bucket).to eq bucket
        expect(key).to eq 'key'
        expect(type).to eq Riak::Crdt::DEFAULT_MAP_BUCKET_TYPE

        expect(operations).to be_a Riak::Crdt::Operation::Update

        expect(operations.value).to be_a Array
        expect(operations.value.first).to be_a Riak::Crdt::Operation::Update
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
