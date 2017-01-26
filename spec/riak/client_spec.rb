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
require 'riak/errors/protobuffs_error'

describe Riak::Client, test_client: true do
  describe "when initializing" do
    it "defaults to a single local node" do
      client = Riak::Client.new
      expect(client.nodes).to eq([Riak::Client::Node.new(client)])
    end

    it "accepts a host" do
      client = Riak::Client.new :host => "riak.basho.com"
      expect(client.nodes.size).to eq(1)
      expect(client.nodes.first.host).to eq("riak.basho.com")
    end

    it "accepts a Protobuffs port" do
      client = Riak::Client.new :pb_port => 9000
      expect(client.nodes.size).to eq(1)
      expect(client.nodes.first.host).to eq('127.0.0.1')
      expect(client.nodes.first.pb_port).to eq(9000)
    end

    it "accepts a client ID" do
      client = Riak::Client.new :client_id => "AAAAAA=="
      expect(client.client_id).to eq("AAAAAA==")
    end

    it "creates a client ID if not specified", :integration => true do
      expect(Riak::Client.new(pb_port: test_client.nodes.first.pb_port).
              client_id).to_not be_nil
    end

    it "accepts multiple nodes" do
      client = Riak::Client.new nodes: [
                                  {host: 'riak1.basho.com'},
                                  {host: 'riak2.basho.com', pb_port: 1234},
                                  {host: 'riak3.basho.com', pb_port: 5678}
                                ]
      expect(client.nodes.size).to eq(3)
      expect(client.nodes.first.host).to eq("riak1.basho.com")
    end

    it "maps port to unset nodes, and does not create localhost node" do
      client = Riak::Client.new nodes: [
                                  {host: 'riak1.basho.com'},
                                  {host: 'riak2.basho.com', pb_port: 1234},
                                  {host: 'riak3.basho.com', pb_port: 5678}
                                ], pb_port: 4321
      expect(client.nodes.size).to eq(3)
      expect(client.nodes[0].host).to eq("riak1.basho.com")
      expect(client.nodes[0].pb_port).to eq(4321)
      expect(client.nodes[1].host).to eq("riak2.basho.com")
      expect(client.nodes[1].pb_port).to eq(1234)
    end

    it "defaults to max_retries = 2" do
      client = Riak::Client.new
      expect(client.max_retries).to eq(2)
    end

    it "accepts max_retries option" do
      client = Riak::Client.new :max_retries => 42
      expect(client.max_retries).to eq(42)
    end

    it "accepts timeouts" do
      client = Riak::Client.new(
        :connect_timeout => 1,
        :read_timeout    => 2,
        :write_timeout   => 3
      )
      expect(client.connect_timeout).to eq(1)
      expect(client.read_timeout).to eq(2)
      expect(client.write_timeout).to eq(3)
    end

    it "accepts convert_timestamp" do
      client = Riak::Client.new(
        :convert_timestamp => true
      )
      expect(client.convert_timestamp).to be
    end

    it "has default convert_timestamp of false" do
      client = Riak::Client.new
      expect(client.convert_timestamp).to_not be
    end
  end

  it "exposes a Stamp object" do
    expect(subject).to respond_to(:stamp)
    expect(subject.stamp).to be_kind_of(Riak::Stamp)
  end

  it 'exposes bucket types' do
    bucket_type = nil
    expect{ bucket_type = subject.bucket_type('example') }.to_not raise_error
    expect(bucket_type).to be_a Riak::BucketType
    expect(bucket_type.name).to eq 'example'
  end

  describe "reconfiguring" do
    before :each do
      @client = Riak::Client.new
    end

    describe "setting the client id" do
      it "accepts a string unmodified" do
        @client.client_id = "foo"
        expect(@client.client_id).to eq("foo")
      end

      it "rejects an integer equal to the maximum client id" do
        expect do
          @client.client_id = Riak::Client::MAX_CLIENT_ID
          end.to raise_error(ArgumentError)
      end

      it "rejects an integer larger than the maximum client id" do
        expect do
          @client.client_id = Riak::Client::MAX_CLIENT_ID + 1
        end.to raise_error(ArgumentError)
      end
    end
  end

  describe "choosing a Protobuffs backend" do
    before :each do
      @client = Riak::Client.new
    end

    it "chooses the selected backend" do
      @client.protobuffs_backend = :Beefcake
      @client.protobuffs do |p|
        expect(p).to be_instance_of(Riak::Client::BeefcakeProtobuffsBackend)
      end
    end

    it "tears down the existing Protobuffs connections when changed" do
      expect(@client.protobuffs_pool).to receive(:clear)
      @client.protobuffs_backend = :Beefcake
    end

    it "raises an error when the chosen backend is not valid" do
      expect(Riak::Client::BeefcakeProtobuffsBackend).to receive(:configured?).
                                                          and_return(false)
      expect do
        @client.protobuffs { |x| }
      end.to raise_error Riak::BackendCreationError
    end
  end

  describe "choosing a unified backend" do
    before :each do
      @client = Riak::Client.new
    end

    it "uses Protobuffs when the protocol is pbc" do
      @client.backend do |b|
        expect(b).to be_kind_of(Riak::Client::ProtobuffsBackend)
      end
    end
  end

  describe "retrieving many values" do
    before :each do
      @client = Riak::Client.new
      @bucket = @client.bucket('foo')
      expect(@bucket).to receive(:[]).
                          with('value1').
                          and_return(double('robject'))
      expect(@bucket).to receive(:[]).
                          with('value2').
                          and_return(double('robject'))
      @pairs = [
                [@bucket, 'value1'],
                [@bucket, 'value2']
               ]
    end

    it 'accepts an array of bucket and key pairs' do
      expect{ @client.get_many(@pairs) }.not_to raise_error
    end

    it 'returns a hash of bucket/key pairs and robjects' do
      @results = @client.get_many(@pairs)
      expect(@results).to be_a Hash
      expect(@results.length).to be(@pairs.length)
    end
  end

  describe "retrieving a bucket" do
    before :each do
      @client = Riak::Client.new
      @backend = double("Backend")
      allow(@client).to receive(:backend).and_yield(@backend)
    end

    it "returns a bucket object" do
      expect(@client.bucket("foo")).to be_kind_of(Riak::Bucket)
    end

    it "fetches bucket properties if asked" do
      expect(@backend).to receive(:get_bucket_props) do |b|
        expect(b.name).to eq("foo")
        {}
      end
      @client.bucket("foo", :props => true)
    end

    it "memoizes bucket parameters" do
      @bucket = double("Bucket")
      expect(Riak::Bucket).to receive(:new).
                               with(@client, "baz").
                               once.
                               and_return(@bucket)
      expect(@client.bucket("baz")).to eq(@bucket)
      expect(@client.bucket("baz")).to eq(@bucket)
    end

    it "rejects buckets with zero-length names" do
      expect { @client.bucket('') }.to raise_error(ArgumentError)
    end
  end

  describe "listing buckets" do
    before do
      @client = Riak::Client.new
      @backend = double("Backend")
      allow(@client).to receive(:backend).and_yield(@backend)
    end

    after { Riak.disable_list_exceptions = true }

    it "lists buckets" do
      expect(@backend).to receive(:list_buckets).and_return(%w{test test2})
      buckets = @client.buckets
      expect(buckets.size).to eq(2)
      expect(buckets).to be_all {|b| b.is_a?(Riak::Bucket) }
      expect(buckets[0].name).to eq("test")
      expect(buckets[1].name).to eq("test2")
    end

    it "raises list-error when exceptions are not disabled" do
      Riak.disable_list_exceptions = false
      allow(@backend).to receive(:list_buckets).and_return(%w{test test2})
      expect { @client.buckets }.to raise_error Riak::ListError
    end

    it "supports a timeout option" do
      expect(@backend).to receive(:list_buckets).with(timeout: 1234).and_return(%w{test test2})

      buckets = @client.buckets timeout: 1234
      expect(buckets.size).to eq(2)
    end
  end

  describe "when receiving errors from the backend" do
    before do
      @client = Riak::Client.new
    end

    it "retries on recoverable errors" do
      call_count = 0

      begin
        @client.backend do |b|
          call_count += 1
          raise Riak::ProtobuffsFailedHeader
        end
      rescue RuntimeError
      end

      expect(call_count).to eq(@client.max_retries + 1)
    end

    it "throws a RuntimeError if it runs out of retries" do
      error = nil
      begin
        @client.backend do |b|
          raise Riak::ProtobuffsFailedHeader
        end
      rescue RuntimeError => e
        error = e
      end

      expect(error).not_to be_nil
      expect(error).to be_instance_of(RuntimeError)
    end

    it "logs the error" do
      expect(Riak.logger).to receive(:warn).with(/Riak::ProtobuffsFailedHeader/).at_least(:once)

      begin
        @client.backend do |b|
          raise Riak::ProtobuffsFailedHeader
        end
      rescue RuntimeError
      end
    end
  end
end
