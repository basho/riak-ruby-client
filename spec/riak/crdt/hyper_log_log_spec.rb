# Copyright 2010-present Basho Technologies, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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

    it 'batches properly' do
      expect(operator).
        to receive(:operate) { |bucket, key, type, operations|
          expect(bucket).to eq bucket
          expect(key).to eq 'key'
          expect(type).to eq subject.bucket_type

          expect(operations).to be_a Riak::Crdt::Operation::Update
          expect(operations.value).to eq({add: %w{alpha bravo}})
        }.
        and_return(response)

      subject.instance_variable_set :@context, 'placeholder'

      subject.batch do |s|
        s.add 'alpha'
        s.add 'bravo'
      end
    end
  end
end
