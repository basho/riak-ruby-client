require 'spec_helper'
require_relative 'shared_examples'

describe Riak::Crdt::Counter do
  let(:bucket) do
    double('bucket').tap do |b|
      allow(b).to receive(:name).and_return('bucket')
      allow(b).to receive(:is_a?).and_return(true)
    end
  end
  it 'should be initialized with bucket, key, and optional bucket-type' do
    expect{ described_class.new bucket, 'key' }.to_not raise_error
    expect{ described_class.new bucket, 'key', 'type' }.to_not raise_error
  end

  subject{ described_class.new bucket, 'key' }

  describe 'with a client' do
    let(:response){ double 'response', key: nil }
    let(:operator){ double 'operator' }
    let(:backend){ double 'backend' }
    let(:client){ double 'client' }
    
    before(:each) do
      allow(bucket).to receive(:client).and_return(client)
      allow(client).to receive(:backend).and_yield(backend)
      allow(backend).to receive(:crdt_operator).and_return(operator)
    end
    
    include_examples 'Counter CRDT'

    it 'should batch properly' do
      expect(operator).
        to receive(:operate) { |bucket, key, type, operations|
        expect(bucket).to eq bucket
        expect(key).to eq 'key'
        expect(type).to eq subject.bucket_type

        expect(operations).to be_a Riak::Crdt::Operation::Update
        expect(operations.value).to eq 5
      }.
        and_return(response)

      subject.batch do |s|
        s.increment 4 # 4
        s.decrement 2 # 2
        s.increment 4 # 6
        s.decrement   # 5
      end
    end
  end
end
