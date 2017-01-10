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

describe Riak::Crdt::InnerSet do
  let(:parent){ double 'parent' }
  let(:set_name){ 'set name' }
  subject do
    described_class.new(parent, []).tap do |s|
      s.name = set_name
    end
  end

  include_examples 'Set CRDT'

  it 'sends additions to the parent' do
    expect(parent).to receive(:operate) do |name, op|
      expect(name).to eq set_name
      expect(op.type).to eq :set
      expect(op.value).to eq add: 'el'
    end

    subject.add 'el'

    expect(parent).to receive(:operate) do |name, op|
      expect(name).to eq set_name
      expect(op.type).to eq :set
      expect(op.value).to eq remove: 'el2'
    end
    allow(parent).to receive(:context?).and_return(true)

    subject.remove 'el2'
  end
end
