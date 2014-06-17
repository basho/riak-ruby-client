require 'spec_helper'

describe Riak::Counter do
  describe "initialization" do
    before :each do
      @bucket = Riak::Bucket.allocate
      @key = 'key'
      @bucket.stub allow_mult: true
      @bucket.stub(client: double('client'))
      @bucket.stub('is_a?' => true)
    end

    it "should set the bucket and key" do
      ctr = Riak::Counter.new @bucket, @key
      expect(ctr.bucket).to eq(@bucket)
      expect(ctr.key).to eq(@key)
    end

    it "should require allow_mult" do
      @bad_bucket = Riak::Bucket.allocate
      @bad_bucket.stub allow_mult: false
      @bad_bucket.stub(client: double('client'))

      expect{ctr = Riak::Counter.new @bad_bucket, @key}.to raise_error(ArgumentError)
      
    end
  end
  
  describe "incrementing and decrementing" do
    before :each do
      @backend = double 'backend'

      @client = double 'client'
      allow(@client).to receive(:backend).and_yield @backend

      @bucket = Riak::Bucket.allocate
      @bucket.stub allow_mult: true
      @bucket.stub client: @client

      @key = 'key'

      @ctr = Riak::Counter.new @bucket, @key

      @increment_expectation = proc{|n| expect(@backend).to receive(:post_counter).with(@bucket, @key, n, {})}
    end

    it "should increment by 1 by default" do
      @increment_expectation[1]
      @ctr.increment
    end

    it "should support incrementing by positive numbers" do
      @increment_expectation[15]
      @ctr.increment 15
    end

    it "should support incrementing by negative numbers" do
      @increment_expectation[-12]
      @ctr.increment -12
    end

    it "should decrement by 1 by default" do
      @increment_expectation[-1]
      @ctr.decrement
    end

    it "should support decrementing by positive numbers" do
      @increment_expectation[-30]
      @ctr.decrement 30
    end

    it "should support decrementing by negative numbers" do
      @increment_expectation[41]
      @ctr.decrement -41
    end

    it "should forbid incrementing by non-integers" do
      [1.1, nil, :'1', '1', 2.0/2, [1]].each do |candidate|
        expect do
          @ctr.increment candidate
          raise candidate.to_s
        end.to raise_error(ArgumentError)
      end
    end
  end

  describe "failure modes" do
    before :each do
      @nodes = 10.times.map do |n|
        {pb_port: "100#{n}7"}
      end

      @fake_pool = double 'pool'
      @backend = double 'backend'
        
      @client = Riak::Client.new nodes: @nodes
      @client.instance_variable_set :@protobuffs_pool, @fake_pool

      allow(@fake_pool).to receive(:take).and_yield(@backend)

      @bucket = Riak::Bucket.allocate
      @bucket.stub allow_mult: true
      @bucket.stub client: @client

      @key = 'key'

      @expect_post = expect(@backend).to receive(:post_counter).with(@bucket, @key, 1, {})

      @ctr = Riak::Counter.new @bucket, @key
    end

    it "should not retry on timeout" do
      @expect_post.once.and_raise('timeout')
      expect(proc { @ctr.increment }).to raise_error
    end
    
    it "should not retry on quorum failure" do
      @expect_post.once.and_raise('quorum not satisfied')
      expect(proc { @ctr.increment }).to raise_error
    end
  end
end
