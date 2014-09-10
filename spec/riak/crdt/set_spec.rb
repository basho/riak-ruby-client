require 'spec_helper'
require_relative 'shared_examples'

describe Riak::Crdt::Set do
  let(:bucket) do
    double('bucket').tap do |b|
      allow(b).to receive(:name).and_return('bucket')
      allow(b).to receive(:is_a?).and_return(true)
    end
  end

  it 'should be initialized with bucket, key, and optional bucket-type' do
    expect{described_class.new bucket, 'key', 'optional bucket type'}.
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

    include_examples 'Set CRDT'

    it 'should batch properly' do
      expect(operator).
        to receive(:operate) { |bucket, key, type, operations|

        expect(bucket).to eq bucket
        expect(key).to eq 'key'
        expect(type).to eq subject.bucket_type

        expect(operations).to be_a Riak::Crdt::Operation::Update
        expect(operations.value).to eq({
                                         add: %w{alpha bravo},
                                         remove: %w{foxtrot}
                                       })
      }.
        and_return(response)

      subject.instance_variable_set :@context, 'placeholder'

      subject.batch do |s|
        s.add 'alpha'
        s.add 'bravo'
        s.remove 'foxtrot'
      end
    end
  end
end
