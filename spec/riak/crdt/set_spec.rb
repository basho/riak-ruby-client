require 'spec_helper'
require_relative 'shared_examples'

describe Riak::Crdt::Set do
  let(:bucket) do
    double('bucket').tap do |b|
      b.stub(:name).and_return('bucket')
      b.stub(:is_a?).and_return(true)
    end
  end

  it 'should be initialized with bucket, key, and optional bucket-type' do
    expect{described_class.new bucket, 'key', 'optional bucket type'}.
      to_not raise_error
  end

  subject{ described_class.new bucket, 'key' }

  describe 'with a client' do
    let(:operator){ double 'operator' }
    let(:backend){ double 'backend' }
    let(:client){ double 'client' }

    before(:each) do
      bucket.stub(:client).and_return(client)
      client.stub(:backend).and_return(backend)
      backend.stub(:crdt_operator).and_return(operator)
    end

    include_examples 'Set CRDT'

    it 'should batch properly' do
      operator.
        should_receive(:operate) do |bucket, key, type, operations|

        expect(bucket).to eq bucket
        expect(key).to eq 'key'
        expect(type).to eq Riak::Crdt::DEFAULT_SET_BUCKET_TYPE

        expect(operations).to be_a Riak::Crdt::Operation::Update
        expect(operations.value).to eq({
                                         add: %w{alpha bravo},
                                         remove: %w{foxtrot}
                                       })
      end

      subject.batch do |s|
        s.add 'alpha'
        s.add 'bravo'
        s.remove 'foxtrot'
      end
    end
  end
end
