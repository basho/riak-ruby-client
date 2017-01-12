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

describe 'Grow Only CRDT set validation', integration: true, test_client: true do
  let(:bucket){ random_bucket 'crdt_validation' }
  let(:set){ Riak::Crdt::GrowOnlySet.new bucket, random_key }

  it 'adds duplicate members' do
    set.batch do |s|
      s.add 'X'
      s.add 'Y'
    end

    set.reload

    expect{ set.add 'X' }.to_not raise_error

    set2 = Riak::Crdt::GrowOnlySet.new bucket, set.key
    expect(set2.members).to eq ::Set.new(%w{X Y})
  end
end
