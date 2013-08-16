require 'spec_helper'

describe Riak::ListBuckets do
  before :each do
    @client = Riak::Client.new protocol: 'pbc'
    @backend = mock 'backend'
    @fake_pool = mock 'connection pool'
    @fake_pool.stub(:take).and_yield(@backend)

    @expect_list = @backend.should_receive(:list_buckets)

    @client.instance_variable_set :@protobuffs_pool, @fake_pool
  end

  describe "non-streaming" do
    it 'should call the backend without a block' do
      @expect_list.with({}).and_return(%w{a b c d})

      @client.list_buckets
    end
  end

  describe "streaming" do
    it 'should call the backend with a block' do
      @expect_list.
        and_yield(%w{abc abd abe}).
        and_yield(%w{bbb ccc ddd})

      @yielded = []

      @client.list_buckets do |bucket|
        @yielded << bucket
      end

      @yielded.each do |b|
        b.should be_a Riak::Bucket
      end
      @yielded.map(&:name).should == %w{abc abd abe bbb ccc ddd}
    end
  end
end
