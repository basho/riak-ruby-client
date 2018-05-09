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

describe Riak::Crdt::InnerRegister do
  let(:parent){ double 'parent' }
  subject { described_class.new parent, "espressos" }

  it 'feels like a string' do
    expect(subject).to match 'espressos'
    expect{ subject.gsub('s', 'x') }.to_not raise_error
    expect(subject.gsub('s', 'x')).to eq 'exprexxox'
  end

  describe 'immutability' do
    it 'is frozen' do
      expect(subject.frozen?).to be
    end
    it "isn't be gsub!-able" do
      # "gsub!-able" is awful, open to suggestions
      expect{ subject.gsub!('s', 'x') }.to raise_error(RuntimeError)
    end
  end

  describe 'updating' do
    let(:new_value){ 'new value' }
    it "asks the class for an update operation" do
      operation = described_class.update(new_value)

      expect(operation.value).to eq new_value
      expect(operation.type).to eq :register
    end
  end

  describe 'deleting' do
    it 'asks the class for a delete operation' do
      operation = described_class.delete

      expect(operation.type).to eq :register
    end
  end
end
