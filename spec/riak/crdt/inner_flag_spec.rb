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

describe Riak::Crdt::InnerFlag do
  let(:parent){ double 'parent' }
  describe 'a truthy flag' do
    subject { described_class.new parent, true }

    it 'feels truthy' do
      expect(subject).to be
    end
  end

  describe 'a falsey flag' do
    subject { described_class.new parent, false }

    it 'feels falsey' do
      expect(subject).to_not be
    end
  end

  describe 'updating' do
    let(:new_value){ false }

    it 'asks the class for an update operation' do
      operation = described_class.update(new_value)

      expect(operation.value).to eq new_value
      expect(operation.type).to eq :flag
    end
  end

  describe 'deleting' do
    it 'asks the class for a delete operation' do
      operation = described_class.delete

      expect(operation.type).to eq :flag
    end
  end
end
