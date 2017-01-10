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

describe "CRDT configuration", integration: true, test_client: true do
  SETS = Riak::Crdt::DEFAULT_BUCKET_TYPES[:set]
  let(:bucket) { random_bucket }

  it "allows default bucket-types to be configured for each data type" do
    expect(Riak::Crdt::Set.new(bucket, 'set').bucket_type).to eq SETS

    Riak::Crdt::DEFAULT_BUCKET_TYPES[:set] = 'new_set_default'
    expect(Riak::Crdt::Set.new(bucket, 'set').bucket_type).to eq 'new_set_default'

    Riak::Crdt::DEFAULT_BUCKET_TYPES[:set] = SETS
    expect(Riak::Crdt::Set.new(bucket, 'set').bucket_type).to eq SETS
  end

  describe 'overriding bucket-types' do
    let(:name){ 'other_counters' }
    let(:type){ test_client.bucket_type name }
    let(:typed_bucket){ type.bucket bucket.name }

    it "overrides with a string" do
      ctr = Riak::Crdt::Counter.new(bucket, 'ctr', name)
      expect(ctr.bucket_type).to eq name
    end

    it "overrides with a typed bucket" do
      ctr = Riak::Crdt::Counter.new(typed_bucket, 'ctr')
      expect(ctr.bucket_type).to eq name
    end

    it "overrides with a bucket type object" do
      ctr = Riak::Crdt::Counter.new(bucket, 'ctr', type)
      expect(ctr.bucket_type).to eq name
    end
  end
end
