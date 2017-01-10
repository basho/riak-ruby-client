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

describe 'Secondary indexes', test_client: true, integration: true do
  let(:bucket){ random_bucket '2i-integration' }
  before do
    50.times do |i|
      bucket.new(i.to_s).tap do |obj|
        obj.indexes["index_int"] << i
        obj.indexes["index_bin"] << i.to_s
        obj.data = [i]
        obj.store
      end
    end
  end

  it "finds keys for an equality query" do
    expect(bucket.get_index('index_int', 20)).to eq(["20"])
  end

  it "finds keys for a range query" do
    expect(bucket.get_index('index_int', 19..21)).to match_array(%w(19 20 21))
  end

  it "returns an empty array for a query that does not match any keys" do
    expect(bucket.get_index('index_int', 10000)).to eq([])
  end

  it "returns terms" do
    results = nil
    expect do
      results = bucket.get_index('index_int',
                                 19..21,
                                 return_terms: true)
    end.to_not raise_error

    expect(results).to be_a Array
    expect(results.with_terms).to be_a Hash
  end

  it "returns terms matching a term_regex" do
    results = nil
    expect do
      results = bucket.get_index('index_bin',
                                 '19'..'21',
                                 return_terms: true,
                                 term_regex: '20')
    end.to_not raise_error

    terms = results.with_terms

    expect(terms['20']).to be
    expect(terms['19']).to be_empty
  end

  describe "with symbolized index names" do
    it "stores and queries indexes correctly" do
      obj = bucket.new random_key
      obj.indexes[:coat_pattern_bin] << "tuxedo"
      obj.data = "tuxedo"

      expect{ obj.store }.to_not raise_error

      results = nil
      expect do
        results = bucket.get_index(:coat_pattern_bin,
                                   'tuxedo')
      end.to_not raise_error

      expect(results.first).to eq obj.key
    end
  end
end
