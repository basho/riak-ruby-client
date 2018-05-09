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

describe Riak::RObject do
  before :each do
    @client = Riak::Client.new
    @bucket = Riak::Bucket.new(@client, "foo")
  end

  describe "initialization" do
    it "sets the bucket" do
      @object = Riak::RObject.new(@bucket, "bar")
      expect(@object.bucket).to eq(@bucket)
    end

    it "sets the key" do
      @object = Riak::RObject.new(@bucket, "bar")
      expect(@object.key).to eq("bar")
    end

    it "initializes the links to an empty set" do
      @object = Riak::RObject.new(@bucket, "bar")
      expect(@object.links).to eq(Set.new)
    end

    it "initializes the meta to an empty hash" do
      @object = Riak::RObject.new(@bucket, "bar")
      expect(@object.meta).to eq({})
    end

    it "initializes indexes to an empty hash with a Set for the default value" do
      @object = Riak::RObject.new(@bucket, "bar")
      expect(@object.indexes).to be_kind_of(Hash)
      expect(@object.indexes).to be_empty
      expect(@object.indexes['foo_bin']).to be_kind_of(Set)
    end

    it "yields itself to a given block" do
      Riak::RObject.new(@bucket, "bar") do |r|
        expect(r.key).to eq("bar")
      end
    end
  end

  describe "serialization" do
    before :each do
      @object = Riak::RObject.new(@bucket, "bar")
    end

    it 'delegates #serialize to the appropriate serializer for the content type' do
      @object.content_type = 'text/plain'
      expect(Riak::Serializers).to respond_to(:serialize).with(2).arguments
      expect(Riak::Serializers).to receive(:serialize).with('text/plain', "foo").and_return("serialized foo")
      expect(@object.content.serialize("foo")).to eq("serialized foo")
    end

    it 'delegates #deserialize to the appropriate serializer for the content type' do
      @object.content_type = 'text/plain'
      expect(Riak::Serializers).to respond_to(:deserialize).with(2).arguments
      expect(Riak::Serializers).to receive(:deserialize).with('text/plain', "foo").and_return("deserialized foo")
      expect(@object.content.deserialize("foo")).to eq("deserialized foo")
    end
  end

  describe "data access methods" do
    before :each do
      @object = Riak::RObject.new(@bucket, "bar")
      @object.content_type = "application/json"
    end

    describe "for raw data" do
      describe "when unserialized data was already provided" do
        before do
          @object.data = { 'some' => 'data' }
        end

        it "resets unserialized forms when stored" do
          @object.raw_data = value = '{ "raw": "json" }'

          expect(@object.raw_data).to eq(value)
          expect(@object.data).to eq({ "raw" => "json" })
        end

        it "lazily serializes when read" do
          expect(@object.raw_data).to eq('{"some":"data"}')
        end
      end

      it "only marshal/demarshals when necessary" do
        expect(@object).not_to receive(:serialize)
        expect(@object).not_to receive(:deserialize)
        @object.raw_data = value = "{not even valid json!}}"
        expect(@object.raw_data).to eq(value)
      end
    end

    describe "for unserialized data" do
      describe "when raw data was already provided" do
        before do
          @object.raw_data = '{"some":"data"}'
        end

        it "resets previously stored raw data" do
          @object.data = value = { "new" => "data" }
          expect(@object.raw_data).to eq('{"new":"data"}')
          expect(@object.data).to eq(value)
        end

        it "lazily deserializes when read" do
          expect(@object.data).to eq({ "some" => "data" })
        end

        context 'for an IO-like object' do
          let(:io_object) { double(:read => 'the io object') }

          it 'reads the object before deserializing it' do
            expect(@object.content).to receive(:deserialize).with('the io object').and_return('deserialized')
            @object.raw_data = io_object
            expect(@object.data).to eq('deserialized')
          end

          it 'does not allow it to be assigned directly to data' do
            # it should be assigned to raw_data instead
            expect {
              @object.data = io_object
            }.to raise_error(ArgumentError)
          end
        end
      end

      it "only marshal/demarshals when necessary" do
        expect(@object).not_to receive(:serialize)
        expect(@object).not_to receive(:deserialize)
        @object.data = value = { "some" => "data" }
        expect(@object.data).to eq(value)
      end
    end
  end


  describe "instantiating new object from a map reduce operation" do
    before :each do
      allow(@client).to receive(:[]).and_return(@bucket)

      @sample_response = [
                          {"bucket"=>"users",
                            "key"=>"A2IbUQ2KEMbe4WGtdL97LoTi1DN%5B%28%5C%2F%29%5D",
                            "vclock"=> "a85hYGBgzmDKBVIsCfs+fc9gSN9wlA8q/hKosDpIOAsA",
                            "values"=> [
                                        {"metadata"=>
                                          {"Links"=>[%w(addresses A2cbUQ2KEMbeyWGtdz97LoTi1DN home_address)],
                                            "X-Riak-VTag"=>"5bnavU3rrubcxLI8EvFXhB",
                                            "content-type"=>"application/json",
                                            "X-Riak-Last-Modified"=>"Mon, 12 Jul 2010 21:37:43 GMT",
                                            "X-Riak-Meta"=>{"X-Riak-Meta-King-Of-Robots"=>"I"},
                                            "index" => {
                                              "email_bin" => ["sean@basho.com", "seancribbs@gmail.com"],
                                              "rank_int" => 50
                                            }
                                          },
                                          "data"=>
                                          "{\"email\":\"mail@test.com\",\"_type\":\"User\"}"
                                        }
                                       ]
                          }
                         ]
      @object = Riak::RObject.load_from_mapreduce(@client, @sample_response).first
      expect(@object).to be_kind_of(Riak::RObject)
    end

    it "loads the content type" do
      expect(@object.content_type).to eq("application/json")
    end

    it "loads the body data" do
      expect(@object.data).to be_present
    end

    it "deserializes the body data" do
      expect(@object.data).to eq({"email" => "mail@test.com", "_type" => "User"})
    end

    it "sets the vclock" do
      expect(@object.vclock).to eq("a85hYGBgzmDKBVIsCfs+fc9gSN9wlA8q/hKosDpIOAsA")
      expect(@object.causal_context).to eq @object.vclock
    end

    it "loads and parse links" do
      expect(@object.links.size).to eq(1)
      expect(@object.links.first.url).to eq("/riak/addresses/A2cbUQ2KEMbeyWGtdz97LoTi1DN")
      expect(@object.links.first.rel).to eq("home_address")
    end

    it "loads and parse indexes" do
      expect(@object.indexes.size).to eq(2)
      expect(@object.indexes['email_bin'].size).to eq(2)
      expect(@object.indexes['rank_int'].size).to eq(1)
    end

    it "sets the ETag" do
      expect(@object.etag).to eq("5bnavU3rrubcxLI8EvFXhB")
    end

    it "sets modified date" do
      expect(@object.last_modified.to_i).to eq(Time.httpdate("Mon, 12 Jul 2010 21:37:43 GMT").to_i)
    end

    it "loads meta information" do
      expect(@object.meta["King-Of-Robots"]).to eq(["I"])
    end

    it "sets the key" do
      expect(@object.key).to eq("A2IbUQ2KEMbe4WGtdL97LoTi1DN[(\\/)]")
    end

    it "doesn't set conflict when there is none" do
      expect(@object.conflict?).to be_falsey
    end

    it "doesn't set tombstone when there is none" do
      expect(@object.tombstone?).to be_falsey
    end

    it 'returns [RContent] for siblings' do
      expect(@object.siblings).to eq([@object.content])
    end

    describe "when there are multiple values in an object" do
      before :each do
        response = @sample_response.dup
        response[0]['values'] << {
          "metadata"=> {
            "Links"=>[],
            "X-Riak-VTag"=>"7jDZLdu0fIj2iRsjGD8qq8",
            "content-type"=>"application/json",
            "X-Riak-Last-Modified"=>"Mon, 14 Jul 2010 19:28:27 GMT",
            "X-Riak-Meta"=>[]
          },
          "data"=> "{\"email\":\"mail@domain.com\",\"_type\":\"User\"}"
        }
        @object = Riak::RObject.load_from_mapreduce( @client, response ).first
      end

      it "exposes siblings" do
        expect(@object.siblings.size).to eq(2)
        expect(@object.siblings[0].etag).to eq("5bnavU3rrubcxLI8EvFXhB")
        expect(@object.siblings[1].etag).to eq("7jDZLdu0fIj2iRsjGD8qq8")
      end

      it "raises the conflict? flag when in conflict" do
        expect { @object.data }.to raise_error(Riak::Conflict)
        expect(@object).to be_conflict
      end
    end
  end

  it "doesn't allow duplicate links" do
    @object = Riak::RObject.new(@bucket, "foo")
    @object.links << Riak::Link.new("/riak/foo/baz", "next")
    @object.links << Riak::Link.new("/riak/foo/baz", "next")
    expect(@object.links.length).to eq(1)
  end

  it "allows mass-overwriting indexes while preserving default behavior" do
    @object = described_class.new(@bucket, 'foo')
    @object.indexes = {"ts_int" => [12345], "foo_bin" => "bar"}
    expect(@object.indexes['ts_int']).to eq(Set.new([12345]))
    expect(@object.indexes['foo_bin']).to eq(Set.new(["bar"]))
    expect(@object.indexes['unset_bin']).to eq(Set.new)
  end

  describe "when storing the object normally" do
    before :each do
      @backend = double("Backend")
      allow(@client).to receive(:backend).and_yield(@backend)
      @object = Riak::RObject.new(@bucket)
      @object.content_type = "text/plain"
      @object.data = "This is some text."
      # @headers = @object.store_headers
    end

    it "raises an error when the content_type is blank" do
      expect do
        @object.content_type = nil
        @object.store
      end.to raise_error(ArgumentError)
      expect do
        @object.content_type = '   '
        @object.store
      end.to raise_error(ArgumentError)
    end

    it "raises an error when given an empty string as key" do
      expect do
        @object.key = ''
        @object.store
      end.to raise_error(ArgumentError)
    end

    it "passes quorum parameters and returnbody to the backend" do
      @object.key = 'foo'
      expect(@backend).to receive(:store_object).
                           with(@object,
                                returnbody: false,
                                w: 3,
                                dw: 2).
                           and_return(true)
      @object.store(returnbody: false, w: 3, dw: 2)
    end

    it "raises an error if the object is in conflict" do
      @object.siblings << Riak::RContent.new(@object)
      expect { @object.store }.to raise_error(Riak::Conflict)
    end
  end

  describe "when reloading the object" do
    before :each do
      @backend = double("Backend")
      allow(@client).to receive(:backend).and_yield(@backend)
      @object = Riak::RObject.new(@bucket, "bar")
      @object.vclock = "somereallylongstring"
    end

    it "returns without requesting if the key is blank" do
      @object.key = nil
      expect(@backend).not_to receive(:reload_object)
      @object.reload
    end

    it "returns without requesting if the vclock is blank" do
      @object.vclock = nil
      expect(@backend).not_to receive(:reload_object)
      @object.reload
    end

    it "reloads the object if the key is present" do
      expect(@backend).to receive(:reload_object).with(@object, {}).and_return(@object)
      @object.reload
    end

    it "passes the requested R quorum to the backend" do
      expect(@backend).to receive(:reload_object).with(@object, :r => 2).and_return(@object)
      @object.reload :r => 2
    end

    it "disables matching conditions if the key is present and the :force option is given" do
      expect(@backend).to receive(:reload_object) do |obj, _|
        expect(obj.etag).to be_nil
        expect(obj.last_modified).to be_nil
        obj
      end
      @object.reload :force => true
    end
  end

  describe "when deleting" do
    before :each do
      @backend = double("Backend")
      allow(@client).to receive(:backend).and_yield(@backend)
      @object = Riak::RObject.new(@bucket, "bar")
    end

    it "makes a DELETE request to the Riak server and freeze the object" do
      expect(@backend).to receive(:delete_object).with(@bucket, "bar", {})
      @object.delete
      expect(@object).to be_frozen
    end

    it "does nothing when the key is blank" do
      expect(@backend).not_to receive(:delete_object)
      @object.key = nil
      @object.delete
    end

    it "raises a failed request exception when the backend returns a server error" do
      expect(@backend).to receive(:delete_object).
        and_raise(Riak::ProtobuffsFailedRequest.new(:server_error, "server error"))
      expect { @object.delete }.to raise_error(Riak::FailedRequest)
    end

    it "sends the vector clock to the backend if present" do
      @object.vclock = "somevclock"
      expect(@backend).to receive(:delete_object).with(@bucket, "bar", {:vclock => "somevclock"})
      @object.delete
    end
  end

  it "doesn't convert to link without a tag" do
    @object = Riak::RObject.new(@bucket, "bar")
    expect { @object.to_link }.to raise_error(ArgumentError)
  end

  it "converts to a link having the same url and a supplied tag" do
    @object = Riak::RObject.new(@bucket, "bar")
    expect(@object.to_link("next")).to eq(Riak::Link.new("/riak/foo/bar", "next"))
  end

  it "escapes the bucket and key when converting to a link" do
    @object = Riak::RObject.new(@bucket, "deep/path")
    expect(@bucket).to receive(:name).and_return("bucket spaces")
    expect(@object.to_link("bar").url).to eq("/riak/bucket%20spaces/deep%2Fpath")
  end

  describe "#inspect" do
    let(:object) { Riak::RObject.new(@bucket) }

    it "provides useful output even when the key is nil" do
      expect { object.inspect }.not_to raise_error
      expect(object.inspect).to be_kind_of(String)
    end

    it 'uses the serializer output in inspect' do
      object.raw_data = { 'a' => 7 }
      object.content_type = 'inspect/type'
      Riak::Serializers['inspect/type'] = Object.new.tap do |o|
        def o.load(object)
          "serialize for inspect"
        end
      end

      expect(object.inspect).to match(/serialize for inspect/)
    end
  end

  describe '.on_conflict' do
    it 'adds the hook to the list of on conflict hooks' do
      hook_run = false
      expect(described_class.on_conflict_hooks).to be_empty
      described_class.on_conflict { hook_run = true }
      expect(described_class.on_conflict_hooks.size).to eq(1)
      described_class.on_conflict_hooks.first.call
      expect(hook_run).to eq(true)
    end
  end

  describe '#attempt_conflict_resolution' do
    let(:conflicted_robject) do
      Riak::RObject.new(@bucket, "conflicted") do |r|
        r.siblings = [ Riak::RContent.new(r), Riak::RContent.new(r)]
      end
    end
    let(:resolved_robject) { Riak::RObject.new(@bucket, "resolved") }
    let(:invoked_resolvers) { [] }
    let(:resolver_1) do
      lambda do |r|
        invoked_resolvers << :resolver_1
        nil
      end
    end
    let(:resolver_2) do
      lambda do |r|
        invoked_resolvers << :resolver_2
        :not_an_robject
      end
    end
    let(:resolver_3) do
      lambda do |r|
        invoked_resolvers << :resolver_3
        r
      end
    end
    let(:resolver_4) do
      lambda do |r|
        invoked_resolvers << :resolver_4
        resolved_robject
      end
    end

    before(:each) do
      described_class.on_conflict(&resolver_1)
      described_class.on_conflict(&resolver_2)
    end

    it 'calls each resolver until one of them returns an robject' do
      described_class.on_conflict(&resolver_3)
      described_class.on_conflict(&resolver_4)
      conflicted_robject.attempt_conflict_resolution
      expect(invoked_resolvers).to eq([:resolver_1, :resolver_2, :resolver_3])
    end

    it 'returns the robject returned by the last invoked resolver' do
      described_class.on_conflict(&resolver_4)
      expect(conflicted_robject.attempt_conflict_resolution).to be(resolved_robject)
    end

    it 'allows the resolver to return the original robject' do
      described_class.on_conflict(&resolver_3)
      expect(conflicted_robject.attempt_conflict_resolution).to be(conflicted_robject)
    end

    it 'returns the robject and does not call any resolvers if the robject is not in conflict' do
      expect(resolved_robject.attempt_conflict_resolution).to be(resolved_robject)
      expect(invoked_resolvers).to eq([])
    end

    it 'returns the original robject if none of the resolvers returns an robject' do
      expect(conflicted_robject.attempt_conflict_resolution).to be(conflicted_robject)
      expect(invoked_resolvers).to eq([:resolver_1, :resolver_2])
    end
  end

  describe "when working with a tombstone object" do
    before :each do
      @backend = double("Backend")
      allow(@client).to receive(:backend).and_yield(@backend)
      @object =Riak::RObject.new(@bucket)
      @object.siblings.clear
      @object.vclock = "notnil"
    end

    it "sets the tombstone flag" do
      expect(@object.tombstone?).to be true
    end

    it "does not set the conflict flag" do
      expect(@object.conflict?).to be_falsey
    end

    it "does not allow you to store a tombstone" do
      expect { @object.store }.to raise_error(Riak::Tombstone)
    end

    it "does not allow you to fetch a value" do
      expect { @object.content }.to raise_error(Riak::Tombstone)
    end

    it "allows you to revive the object" do
      @object.revive
      expect(@object.tombstone?).to be_falsey
      expect(@object.siblings.empty?).to be_falsey
    end

    it "allows revived objects to be stored" do
      expect(@object.tombstone?).to be true
      @object.revive
      @object.content_type = "text/plain"
      @object.data = "This is some text."
      expect(@backend).to receive(:store_object).and_return(true)
      @object.store
    end
  end
end
