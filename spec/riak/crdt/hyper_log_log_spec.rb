require 'spec_helper'
require_relative 'shared_examples'

describe Riak::Crdt::HyperLogLog, hll: true do
  let(:bucket) do
    double('bucket').tap do |b|
      allow(b).to receive(:name).and_return('bucket')
      allow(b).to receive(:is_a?).with(Riak::Bucket).and_return(true)
      allow(b).to receive(:is_a?).with(Riak::BucketTyped::Bucket).and_return(false)
    end
  end

  it 'initializes with bucket, key, and bucket-type' do
    expect{described_class.new bucket, 'key', 'bucket type'}.
      to_not raise_error
  end

  subject{ described_class.new bucket, 'key' }

  describe 'with a client' do
    let(:response){ double 'response', key: nil }
    let(:operator){ double 'operator' }
    let(:loader){ double 'loader', get_loader_for_value: nil }
    let(:backend){ double 'backend' }
    let(:client){ double 'client' }

    before(:each) do
      allow(bucket).to receive(:client).and_return(client)
      allow(client).to receive(:backend).and_yield(backend)
      allow(backend).to receive(:crdt_operator).and_return(operator)
      allow(backend).to receive(:crdt_loader).and_return(loader)
    end

    include_examples 'HyperLogLog CRDT'
  end
end
