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

describe Riak::Crdt::Map do
  let(:bucket) do
    double('bucket').tap do |b|
      allow(b).to receive(:name).and_return('bucket')
      allow(b).to receive(:is_a?).with(Riak::Bucket).and_return(true)
      allow(b).to receive(:is_a?).with(Riak::BucketTyped::Bucket).and_return(false)
      allow(b).to receive(:client).and_return(client)
    end
  end
  let(:operator){ double 'operator' }
  let(:loader){ double 'loader' }
  let(:backend){ double 'backend' }
  let(:client){ double 'client' }
  let(:key){ 'map' }

  before(:each) do
    allow(client).to receive(:backend).and_yield(backend)
    allow(backend).to receive(:crdt_operator).and_return(operator)
    allow(backend).to receive(:crdt_loader).and_return(loader)
    allow(loader).to receive(:load).and_return({})
    allow(loader).to receive(:context).and_return('context')
  end

  subject{ described_class.new bucket, key }

  include_examples 'Map CRDT'

  describe 'batch mode' do
    it 'queues up operations' do
      expect(operator).
        to receive(:operate) do |bucket, key_arg, type, operations|

        expect(bucket).to eq bucket
        expect(key_arg).to eq key
        expect(type).to eq subject.bucket_type

        expect(operations.length).to eq 2

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
    it 'submits member operations immediately' do
      expect(operator).
        to receive(:operate) do |bucket, key_arg, type, operations|

        expect(bucket).to eq bucket
        expect(key_arg).to eq key
        expect(type).to eq subject.bucket_type

        expect(operations.length).to eq 1

        expect(operations.first).to be_a Riak::Crdt::Operation::Update

        inner_op = operations.first.value

        expect(inner_op).to be_a Riak::Crdt::Operation::Update
        expect(inner_op.name).to eq 'hasta'
        expect(inner_op.type).to eq :register
        expect(inner_op.value).to eq 'la vista'
      end

      subject.registers['hasta'] = 'la vista' # baby
    end
  end
end
