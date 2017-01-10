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

describe 'Conflict resolution', integration: true, test_client: true do
  let(:bucket) do
    bucket = random_bucket
    bucket.allow_mult = true

    bucket
  end

  subject do
    robj = bucket.new
    robj.content_type = 'application/json'
    robj.data = 100
    robj.store

    robj
  end

  let(:ten_conflicted_robjects) do
    10.times.map do |n|
      t = bucket.new subject.key
      t.data = rand 50
      t.store

      t
    end
  end

  before(:each) do
    ten_conflicted_robjects
    subject.reload
  end

  describe 'on_conflict hooks' do
    after(:each) do
      Riak::RObject.on_conflict_hooks.delete_if{ |i| true }
    end

    it 'resolve ten-sided conflicts' do
      expect(subject).to be_conflict

      # resolver
      Riak::RObject.on_conflict do |obj|
        next nil unless obj.siblings.first.data.is_a? Numeric
        new_sibling = obj.siblings.inject do |memo, sib|
          memo.data = [memo.data, sib.data].max

          memo
        end

        obj.siblings = [new_sibling.dup]

        obj
      end

      subject.attempt_conflict_resolution
      subject.reload

      expect(subject).to_not be_conflict
      expect(subject.data).to eq 100

    end

    it "doesn't resolve impossible conflicts" do
      expect(subject).to be_conflict

      Riak::RObject.on_conflict do |obj|
        nil
      end

      subject.reload

      expect(subject).to be_conflict
    end
  end

  describe 'clobbering siblings without a hook' do
    it 'resolves ten-sided conflicts' do
      expect(subject).to be_conflict
      expect(subject.siblings.length).to eq 11
      max_sibling = subject.siblings.inject do |memo, sib|
        next memo if memo.data > sib.data
        next sib
      end

      subject.siblings = [max_sibling]
      subject.store

      subject.reload
      expect(subject).to_not be_conflict
      expect(subject.data).to eq 100
    end
  end
end
