require 'spec_helper'


describe Riak::Node do
  describe 'when configuring storage backend' do

    it 'should use default(bitcask)' do
      min_config = { :source => '', :root => ''}
      Riak::Node.new(min_config).kv_backend.should == :riak_kv_bitcask_backend
    end

    it 'should use leveldb' do
      leveldb_config = {
        :source => '',
        :root => '',
        :storage_backend => 'riak_kv_eleveldb_backend'
      }
      Riak::Node.new(leveldb_config).kv_backend.should == :riak_kv_eleveldb_backend
    end
  end

  describe 'when configuring riak control' do
    it 'should warn that a port was not set' do
      bad_config = {
        :source => '',
        :root => '',
        :riak_control => {}
      }
      expect { Riak::Node.new(bad_config) }.to raise_error(ArgumentError)
    end

    it 'should warn that a key was not set' do
      bad_config = {
        :source => '',
        :root => '',
        :riak_control => { :port => 1 }
      }
      expect { Riak::Node.new(bad_config) }.to raise_error(ArgumentError)
    end

    it 'should warn that a cert was not set' do
      bad_config = {
        :source => '',
        :root => '',
        :riak_control => { :port => 1, :key => '' }
      }
      expect { Riak::Node.new(bad_config) }.to raise_error(ArgumentError)
    end

    it 'should enable riak control and configure ssl' do
      bad_config = {
        :source => '',
        :root => '',
        :min_port => 9107,
        :riak_control => {
          :key => '/path/to/key.key',
          :cert => '/path/to/cert.crt'
        }
      }
      node = Riak::Node.new(bad_config)
      node.env[:riak_control][:enabled].should be_true
      node.env[:riak_core][:https].should == [['127.0.0.1', 9110]]
      node.env[:riak_core][:ssl].should == [[:certfile, '/path/to/cert.crt'], [:keyfile, '/path/to/key.key']]
    end

    it 'should enable riak control, configure ssl, and override default interface ip' do
      bad_config = {
        :source => '',
        :root => '',
        :min_port => 9703,
        :interface => '0.0.0.0',
        :riak_control => {
          :key => '/path/to/key.key',
          :cert => '/path/to/cert.crt'
        }
      }
      node = Riak::Node.new(bad_config)
      node.env[:riak_control][:enabled].should be_true
      node.env[:riak_core][:https].should == [['0.0.0.0', 9706]]
      node.env[:riak_core][:ssl].should == [[:certfile, '/path/to/cert.crt'], [:keyfile, '/path/to/key.key']]
    end
  end
end
