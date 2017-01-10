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

describe Riak::Crdt::InnerMap do
  let(:parent){ double 'parent' }
  subject{ described_class.new parent, {} }

  include_examples 'Map CRDT'

  let(:populated_contents) do
    {
      counters: {alpha: 0},
      flags: {bravo: true},
      maps: {},
      registers: {delta: 'the expendables' },
      sets: {echo: %w{stallone statham li lundgren}}
    }
  end

  it 'is initializable with a nested hash of maps' do
    expect{described_class.new parent, populated_contents}.
      to_not raise_error
  end

  describe 'deleting the inner map' do
    it 'asks the class for a delete operation' do
      operation = described_class.delete

      expect(operation.type).to eq :map
    end
  end

  describe 'receiving an operation' do
    let(:inner_operation){ double 'inner operation' }
    it 'wraps the operation in an update operation and pass it to the parent' do
      subject.name = 'name'

      expect(parent).to receive(:operate) do |name, op|
        expect(name).to eq 'name'
        expect(op.type).to eq :map
        expect(op.value).to eq inner_operation
      end

      subject.operate inner_operation
    end
  end
end
