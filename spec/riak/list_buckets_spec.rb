require 'spec_helper'

describe Riak::ListBuckets do
  before :each do
    @client = Riak::Client.new
    @backend = double 'backend'
    @fake_pool = double 'connection pool'
    allow(@fake_pool).to receive(:take).and_yield(@backend)

    @expect_list = expect(@backend).to receive(:list_buckets)

    @client.instance_variable_set :@protobuffs_pool, @fake_pool
  end

  describe "non-streaming" do
    it 'calls the backend without a block' do
      @expect_list.with({}).and_return(%w{a b c d})

      @client.list_buckets
    end
  end

  describe "streaming" do
    it 'calls the backend with a block' do
      @expect_list.
        and_yield(%w{abc abd abe}).
        and_yield(%w{bbb ccc ddd})

      @yielded = []

      @client.list_buckets do |bucket|
        @yielded << bucket
      end

      @yielded.each do |b|
        expect(b).to be_a Riak::Bucket
      end
      expect(@yielded.map(&:name)).to eq(%w{abc abd abe bbb ccc ddd})
    end
  end
end
