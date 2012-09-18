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
end
