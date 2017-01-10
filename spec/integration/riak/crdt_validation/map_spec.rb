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

describe 'CRDT map validation', integration: true, test_client: true do
  let(:bucket){ random_bucket 'crdt_validation' }
  let(:map){ Riak::Crdt::Map.new bucket, random_key }

  it 'deletes sets and re-add entries' do
    map.batch do |m|
      m.sets['set'].add 'X'
      m.sets['set'].add 'Y'
    end

    map.reload
    expect(map.sets['set'].include? 'Y').to be

    expect do
      map.batch do |m|
        m.sets.delete 'set'
        m.sets['set'].add 'Z'
      end
    end.to_not raise_error

    map2 = Riak::Crdt::Map.new bucket, map.key

    expect(map2.sets['set'].members).to eq ::Set.new(['Z'])
  end

  it 'deletes counters and increments counters' do
    map.counters['counter'].increment 5

    map.reload

    expect(map.counters['counter'].value).to eq 5

    map.batch do |m|
      m.counters['counter'].increment 2
      m.counters.delete 'counter'
    end

    map2 = Riak::Crdt::Map.new bucket, map.key

    expect(map2.counters['counter'].value).to eq(7).or eq(2)
  end

  it 'deletes maps containing sets and re-adds the contained sets' do
    map.batch do |m|
      m.maps['map'].sets['set'].add "X"
      m.maps['map'].sets['set'].add "Y"
    end

    map.reload
    expect(map.maps['map'].sets['set'].members).to eq ::Set.new(%w(X Y))

    map.batch do |m|
      m.maps.delete 'map'
      m.maps['map'].sets['set'].add "Z"
    end

    map2 = Riak::Crdt::Map.new bucket, map.key
    expect(map2.maps['map'].sets['set'].members).to eq ::Set.new(['Z'])
  end
end
