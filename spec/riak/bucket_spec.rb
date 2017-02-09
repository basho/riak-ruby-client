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

require 'riak/errors/list_error'

describe Riak::Bucket do
  before :each do
    @client = Riak::Client.new
    @backend = double("Backend")
    allow(@client).to receive(:backend).and_yield(@backend)
    allow(@client).to receive(:http).and_yield(@backend)
    @bucket = Riak::Bucket.new(@client, "foo")
  end

  describe "when initializing" do
    it "requires a client and a name" do
      expect { Riak::Bucket.new }.to raise_error ArgumentError
      expect { Riak::Bucket.new(@client) }.to raise_error ArgumentError
      expect { Riak::Bucket.new("foo") }.to raise_error ArgumentError
      expect { Riak::Bucket.new("foo", @client) }.to raise_error ArgumentError
      expect { Riak::Bucket.new(@client, "foo") }.not_to raise_error
      expect { Riak::Bucket.new(@client, '') }.to raise_error(ArgumentError)
    end

    it "sets the client and name attributes" do
      bucket = Riak::Bucket.new(@client, "foo")
      expect(bucket.client).to eq(@client)
      expect(bucket.name).to eq("foo")
    end
  end

  describe "accessing keys" do
    it "lists the keys" do
      expect(@backend).to receive(:list_keys).with(@bucket, {}).and_return(["bar"])
      expect(@bucket.keys).to eq(["bar"])
    end

    it "allows streaming keys through block" do
      expect(@backend).to receive(:list_keys).with(@bucket, {}).and_yield([]).and_yield(["bar"]).and_yield(["baz"])
      all_keys = []
      @bucket.keys do |list|
        all_keys.concat(list)
      end
      expect(all_keys).to eq(%w(bar baz))
    end

    it "fetches a fresh list of keys" do
      expect(@backend).to receive(:list_keys).with(@bucket, {}).twice.and_return(["bar"])
      2.times { expect(@bucket.keys).to eq(['bar']) }
    end

    it "raises list error when exceptions are not disabled" do
      Riak.disable_list_exceptions = false
      allow(@backend).to receive(:list_keys).and_return(%w{test test2})
      expect { @bucket.keys }.to raise_error Riak::ListError
      Riak.disable_list_exceptions = true
    end

    it "allows a specified timeout when listing keys" do
      expect(@backend).to receive(:list_keys).with(@bucket, timeout: 1234).and_return(%w{bar})

      keys = @bucket.keys timeout: 1234

      expect(keys).to eq(%w{bar})
    end
  end

  describe "accessing a counter" do
    it "returns a counter object" do
      expect(Riak::Counter).to receive(:new).with(@bucket, 'asdf').and_return('example counter')

      new_counter = @bucket.counter 'asdf'

      expect(new_counter).to eq('example counter')
    end
  end

  describe "setting the bucket properties" do
    it "prefetches the properties when they are not present" do
      allow(@backend).to receive(:set_bucket_props)
      expect(@backend).to receive(:get_bucket_props).with(@bucket, {  }).and_return({"name" => "foo"})
      @bucket.props = {"precommit" => []}
    end

    it "sets the new properties on the bucket" do
      @bucket.instance_variable_set(:@props, {}) # Pretend they are there
      expect(@backend).to receive(:set_bucket_props).with(@bucket, { :name => "foo" }, nil)
      @bucket.props = { :name => "foo" }
    end

    it "raises an error if an invalid type is given" do
      expect { @bucket.props = "blah" }.to raise_error(ArgumentError)
    end
  end

  describe "fetching the bucket properties" do
    it "fetches properties on first access" do
      expect(@bucket.instance_variable_get(:@props)).to be_nil
      expect(@backend).to receive(:get_bucket_props).with(@bucket, {  }).and_return({"name" => "foo"})
      expect(@bucket.props).to eq({"name" => "foo"})
    end

    it "memoizes fetched properties" do
      expect(@backend).to receive(:get_bucket_props).once.with(@bucket, {  }).and_return({"name" => "foo"})
      expect(@bucket.props).to eq({"name" => "foo"})
      expect(@bucket.props).to eq({"name" => "foo"})
    end
  end

  describe "clearing the bucket properties" do
    it "sends the request and delete the internal properties cache" do
      expect(@client).to receive(:clear_bucket_props).with(@bucket).and_return(true)
      expect(@bucket.clear_props).to be_truthy
      expect(@bucket.instance_variable_get(:@props)).to be_nil
    end
  end

  describe "fetching an object" do
    it "fetches the object via the backend" do
      expect(@backend).to receive(:fetch_object).with(@bucket, "db", {}).and_return(nil)
      @bucket.get("db")
    end

    it "uses the specified R quroum" do
      expect(@backend).to receive(:fetch_object).with(@bucket, "db", {:r => 2}).and_return(nil)
      @bucket.get("db", :r => 2)
    end

    it "disallows fetching an object with a zero-length key" do
      ## TODO: This actually tests the Client object, but there is no suite
      ## of tests for its generic interface.
      expect { @bucket.get('') }.to raise_error(ArgumentError)
    end
  end

  describe "creating a new blank object" do
    it "instantiates the object with the given key, default to JSON" do
      obj = @bucket.new('bar')
      expect(obj).to be_kind_of(Riak::RObject)
      expect(obj.key).to eq('bar')
      expect(obj.content_type).to eq('application/json')
    end
  end

  describe "fetching or creating a new object" do
    let(:not_found_error){ Riak::ProtobuffsFailedRequest.new :not_found, 'not found' }
    let(:other_error){ Riak::ProtobuffsFailedRequest.new :server_error, 'server error' }

    it "returns the existing object if present" do
      @object = double("RObject")
      expect(@backend).to receive(:fetch_object).with(@bucket, "db", {}).and_return(@object)
      expect(@bucket.get_or_new('db')).to eq(@object)
    end

    it "creates a new blank object if the key does not exist" do
      expect(@backend).to receive(:fetch_object).and_raise(not_found_error)
      obj = @bucket.get_or_new('db')
      expect(obj.key).to eq('db')
      expect(obj.data).to be_blank
    end

    it "bubbles up non-ok non-missing errors" do
      expect(@backend).to receive(:fetch_object).and_raise(other_error)
      expect { @bucket.get_or_new('db') }.to raise_error(Riak::ProtobuffsFailedRequest)
    end

    it "passes the given R quorum parameter to the backend" do
      @object = double("RObject")
      expect(@backend).to receive(:fetch_object).with(@bucket, "db", {:r => "all"}).and_return(@object)
      expect(@bucket.get_or_new('db', :r => "all")).to eq(@object)
    end
  end

  describe "fetching multiple objects" do
    it 'gets each object individually' do
      @object1 = double('obj1')
      @object2 = double('obj2')
      expect(@bucket).to receive(:[]).with('key1').and_return(@object1)
      expect(@bucket).to receive(:[]).with('key2').and_return(@object2)

      @results = @bucket.get_many %w{key1 key2}

      expect(@results['key1']).to eq(@object1)
      expect(@results['key2']).to eq(@object2)
    end
  end

  describe "querying an index" do
    it "lists the matching keys" do
      expect(@backend).
        to receive(:get_index).
        with(@bucket, "test_bin", "testing", {return_terms: true}).
        and_return(Riak::IndexCollection.new_from_json({
                     'results' => [
                       {'testing' => 'asdf'},
                       {'testing' => 'hjkl'}]
                   }.to_json))
      result = @bucket.get_index("test_bin", "testing", return_terms: true)

      expect(result).to be_a Riak::IndexCollection
      expect(result.to_a).to eq(%w{asdf hjkl})
      expect(result.with_terms).to eq({'testing' => %w{asdf hjkl}})
    end
  end

  describe "get/set allow_mult property" do
    before :each do
      allow(@backend).to receive(:get_bucket_props).and_return({"allow_mult" => false})
    end

    it "extracts the allow_mult property" do
      expect(@bucket.allow_mult).to be_falsey
    end

    it "sets the allow_mult property" do
      expect(@bucket).to receive(:props=).with(hash_including('allow_mult' => true))
      @bucket.allow_mult = true
    end
  end

  describe "get/set the N value" do
    before :each do
      allow(@backend).to receive(:get_bucket_props).and_return({"n_val" => 3})
    end

    it "extracts the N value" do
      expect(@bucket.n_value).to eq(3)
    end

    it "sets the N value" do
      expect(@bucket).to receive(:props=).with(hash_including('n_val' => 1))
      @bucket.n_value = 1
    end
  end

  [:r, :w, :dw, :rw].each do |q|
    describe "get/set the default #{q} quorum" do
      before :each do
        allow(@backend).to receive(:get_bucket_props).and_return({"r" => "quorum", "w" => "quorum", "dw" => "quorum", "rw" => "quorum"})
      end

      it "extracts the default #{q} quorum" do
        expect(@bucket.send(q)).to eq("quorum")
      end

      it "sets the #{q} quorum" do
        expect(@bucket).to receive(:props=).with(hash_including("#{q}" => 1))
        @bucket.send("#{q}=", 1)
      end
    end
  end

  describe "checking whether a key exists" do
    it "returns true if the object does exist" do
      expect(@backend).to receive(:fetch_object).and_return(double)
      expect(@bucket.exists?("foo")).to be_truthy
    end

    it "returns false if the object doesn't exist" do
      expect(@backend).to receive(:fetch_object).
        and_raise(Riak::ProtobuffsFailedRequest.new(:not_found, "not found"))
      expect(@bucket.exists?("foo")).to be_falsey
    end
  end

  describe "deleting an object" do
    it "deletes a key from within the bucket" do
      expect(@backend).to receive(:delete_object).with(@bucket, "bar", {})
      @bucket.delete('bar')
    end

    it "uses the specified RW quorum" do
      expect(@backend).to receive(:delete_object).with(@bucket, "bar", {:rw => "all"})
      @bucket.delete('bar', :rw => "all")
    end
  end
end
