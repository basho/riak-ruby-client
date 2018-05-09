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

describe Riak::Link do
  describe "parsing a link header" do
    it "creates Link objects from the data" do
      result = Riak::Link.parse('</riak/foo/bar>; rel="tag", </riak/foo>; rel="up"')
      expect(result).to be_kind_of(Array)
      expect(result).to be_all {|i| Riak::Link === i }
    end

    it "sets the bucket, key, url and rel parameters properly" do
      result = Riak::Link.parse('</riak/foo/bar>; riaktag="tag", </riak/foo>; rel="up"')
      expect(result[0].url).to eq("/riak/foo/bar")
      expect(result[0].bucket).to eq("foo")
      expect(result[0].key).to eq("bar")
      expect(result[0].rel).to eq("tag")
      expect(result[1].url).to eq("/riak/foo")
      expect(result[1].bucket).to eq("foo")
      expect(result[1].key).to eq(nil)
      expect(result[1].rel).to eq("up")
    end

    it "keeps the url intact if it does not point to a bucket or bucket/key" do
      result = Riak::Link.parse('</mapred>; rel="riak_kv_wm_mapred"')
      expect(result[0].url).to eq("/mapred")
      expect(result[0].bucket).to be_nil
      expect(result[0].key).to be_nil
    end

    it "parses the Riak 1.0 URL scheme" do
      result = Riak::Link.parse('</buckets/b/keys/k>; riaktag="tag"').first
      expect(result.bucket).to eq('b')
      expect(result.key).to eq('k')
      expect(result.tag).to eq('tag')
    end
  end

  context "converting to a string" do
    it "to a string appropriate for use in the Link header" do
      expect(Riak::Link.new("/riak/foo", "up").to_s).to eq('</riak/foo>; riaktag="up"')
      expect(Riak::Link.new("/riak/foo/bar", "next").to_s).to eq('</riak/foo/bar>; riaktag="next"')
      expect(Riak::Link.new("/riak", "riak_kv_wm_raw").to_s).to eq('</riak>; riaktag="riak_kv_wm_raw"')
    end

    it "converts to a string using the new URL scheme" do
      expect(Riak::Link.new("bucket", "key", "tag").to_s(true)).to eq('</buckets/bucket/keys/key>; riaktag="tag"')
      expect(Riak::Link.parse('</riak/bucket/key>; riaktag="tag"').first.to_s(true)).to eq('</buckets/bucket/keys/key>; riaktag="tag"')
    end
  end

  it "converts to a walk spec when pointing to an object" do
    expect(Riak::Link.new("/riak/foo/bar", "next").to_walk_spec.to_s).to eq("foo,next,_")
    expect { Riak::Link.new("/riak/foo", "up").to_walk_spec }.to raise_error(RuntimeError)
  end

  it "is equivalent to a link with the same url and rel" do
    one = Riak::Link.new("/riak/foo/bar", "next")
    two = Riak::Link.new("/riak/foo/bar", "next")
    expect(one).to eq(two)
    expect([one]).to include(two)
    expect([two]).to include(one)
  end

  it "unescapes the bucket name" do
    expect(Riak::Link.new("/riak/bucket%20spaces/key", "foo").bucket).to eq("bucket spaces")
  end

  it "unescapes the key name" do
    expect(Riak::Link.new("/riak/bucket/key%2Fname", "foo").key).to eq("key/name")
  end

  it "doesn't rely on the prefix to equal /riak/ when extracting the bucket and key" do
    link = Riak::Link.new("/raw/bucket/key", "foo")
    expect(link.bucket).to eq("bucket")
    expect(link.key).to eq("key")
  end

  it "constructs from bucket, key and tag" do
    link = Riak::Link.new("bucket", "key", "tag")
    expect(link.bucket).to eq("bucket")
    expect(link.key).to eq("key")
    expect(link.tag).to eq("tag")
    expect(link.url).to eq("/riak/bucket/key")
  end
end
