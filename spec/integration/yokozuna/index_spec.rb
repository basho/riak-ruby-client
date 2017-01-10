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

describe "Yokozuna", test_client: true, integration: true do
  before(:all) do
    @client = test_client

    @index = 'yz_spec-' + random_key
    @schema = 'yz_spec-' + random_key
  end

  context "without any indexes" do
    it "allows index creation" do
      expect(@client.create_search_index(@index, "_yz_default", 3)).to eq(true)
    end
  end

  context "with an index" do
    before :all do
      expect(@client.create_search_index(@index)).to eq(true)
      wait_until{ !@client.get_search_index(@index).nil? }
    end

    it "allows index inspection" do
      expect(@client.get_search_index(@index).name).to eq(@index)
      expect{ @client.get_search_index("herp_derp") }.to raise_error(Riak::ProtobuffsFailedRequest)
    end

    it "has an index list" do
      expect(@client.list_search_indexes.size).to be >= 1
    end

    it "associates a bucket with an index" do
      @bucket = Riak::Bucket.new(@client, @index)
      @bucket.props = {'search_index' => @index}
      @bucket = @client.bucket(@index)
      expect(@bucket.props).to include('search_index' => @index)
    end

    context "associated with a bucket" do
      before :all do
        @bucket = Riak::Bucket.new(@client, @index)
        @bucket.props = {'search_index' => @index}
        @bucket = @client.bucket(@index)
        expect(@bucket.props).to include('search_index' => @index)
      end

      it "indexes on object writes" do
        object = @bucket.get_or_new("cat")
        object.raw_data = {"cat_s"=>"Lela"}.to_json
        object.content_type = 'application/json'
        object.store
        sleep 2.1  # pause for index commit to trigger

        resp = @client.search(@index, "cat_s:Lela")
        expect(resp).to include('docs')
        expect(resp['docs'].size).to eq(1)
      end
    end
  end
end
