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
require 'riak'

describe 'CRDT set validation', integration: true, test_client: true do
  let(:bucket){ random_bucket 'crdt_validation' }
  let(:set){ Riak::Crdt::Set.new bucket, random_key }

  it 'removes recently-added set entries during batch mode' do
    expect do
      set.batch do |s|
        s.add 'X'
        s.add 'Y'
        s.add 'Z'
        s.remove 'Y'
      end
    end.to raise_error Riak::CrdtError::SetRemovalWithoutContextError
  end

  it 'removes non-members with context' do
    set.batch do |s|
      s.add 'X'
      s.add 'Y'
    end

    set.reload

    expect{ set.remove 'bogus' }.to_not raise_error

    set2 = Riak::Crdt::Set.new bucket, set.key
    expect(set2.members).to eq ::Set.new(%w{X Y})
  end

  it 'adds duplicate members' do
    set.batch do |s|
      s.add 'X'
      s.add 'Y'
    end

    set.reload

    expect{ set.add 'X' }.to_not raise_error

    set2 = Riak::Crdt::Set.new bucket, set.key
    expect(set2.members).to eq ::Set.new(%w{X Y})
  end

  it 'no-ops adding then removing a duplicate member' do
    set.batch do |s|
      s.add 'X'
      s.add 'Y'
    end

    set.reload
    expect(set.members).to eq ::Set.new(%w{X Y})

    expect do
      set.batch do |s|
        s.add 'X'
        s.remove 'X'
      end
    end.to_not raise_error

    set2 = Riak::Crdt::Set.new bucket, set.key
    expect(set2.members).to eq ::Set.new(%w{X Y})
  end

  it 'no-ops removing then re-adding a set member' do
    set.batch do |s|
      s.add 'X'
      s.add 'Y'
    end

    set.reload
    expect(set.members).to eq ::Set.new(%w{X Y})

    expect do
      set.batch do |s|
        s.remove 'X'
        s.add 'X'
      end
    end.to_not raise_error

    set2 = Riak::Crdt::Set.new bucket, set.key
    expect(set2.members).to eq ::Set.new(%w{X Y})
  end

  describe 'parallel operations' do
    it 'removes with up-to-date context' do
      set.batch do |s|
        s.add 'X'
        s.add 'Y'
      end

      set_parallel = Riak::Crdt::Set.new bucket, set.key
      set_parallel.add 'Z'

      set.reload

      expect{ set.remove 'Z' }.to_not raise_error

      set2 = Riak::Crdt::Set.new bucket, set.key
      expect(set2.members).to eq ::Set.new(%w{X Y})
    end

    it "doesn't remove with outdated context" do
      set.batch do |s|
        s.add 'X'
        s.add 'Y'
      end

      set.reload

      set_parallel = Riak::Crdt::Set.new bucket, set.key
      set_parallel.add 'Z'

      expect{ set.remove 'Z' }.to_not raise_error

      set2 = Riak::Crdt::Set.new bucket, set.key
      expect(set2.members).to eq ::Set.new(%w{X Y Z})
    end
  end
end
