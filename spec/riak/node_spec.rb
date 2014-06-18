require 'spec_helper'

describe Riak::Client::Node do
  before :each do
    @client = Riak::Client.new
    @node = Riak::Client::Node.new @client
  end

  describe 'when initializing' do
    it 'should default to the local interface on port 8087' do
      node = Riak::Client::Node.new @client
      expect(node.host).to eq('127.0.0.1')
      expect(node.pb_port).to eq(8087)
    end

    it 'should accept a host' do
      node = Riak::Client::Node.new(@client, :host => 'riak.basho.com')
      expect(node.host).to eq("riak.basho.com")
    end

    it 'should accept a Protobuffs port' do
      node = Riak::Client::Node.new @client, :pb_port => 9000
      expect(node.pb_port).to eq(9000)
    end
  end
end
