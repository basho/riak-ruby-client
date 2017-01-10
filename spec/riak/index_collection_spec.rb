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

describe Riak::IndexCollection do
  describe "json initialization" do
    it "accepts a list of keys" do
      @input = {
        'keys' => %w{first second third}
      }.to_json
      expect { @coll = Riak::IndexCollection.new_from_json @input }.not_to raise_error
      expect(%w{first second third}).to eq(@coll)
    end

    it "accepts a list of keys and a continuation" do
      @input = {
        'keys' => %w{first second third},
        'continuation' => 'examplecontinuation'
      }.to_json
      expect { @coll = Riak::IndexCollection.new_from_json @input }.not_to raise_error
      expect(%w{first second third}).to eq(@coll)
      expect(@coll.continuation).to eq('examplecontinuation')
    end

    it "accepts a list of results hashes" do
      @input = {
        'results' => [
          {'first' => 'first'},
          {'second' => 'second'},
          {'second' => 'other'}
        ]
      }.to_json

      expect { @coll = Riak::IndexCollection.new_from_json @input }.not_to raise_error
      expect(%w{first second other}).to eq(@coll)
      expect({'first' => %w{first}, 'second' => %w{second other}}).to eq(@coll.with_terms)
    end

    it "accepts a list of results hashes and a continuation" do
      @input = {
        'results' => [
          {'first' => 'first'},
          {'second' => 'second'},
          {'second' => 'other'}
        ],
        'continuation' => 'examplecontinuation'
      }.to_json

      expect { @coll = Riak::IndexCollection.new_from_json @input }.not_to raise_error
      expect(%w{first second other}).to eq(@coll)
      expect(@coll.continuation).to eq('examplecontinuation')
      expect({'first' => %w{first}, 'second' => %w{second other}}).to eq(@coll.with_terms)
    end
  end
end
