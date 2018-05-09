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

describe Riak::Counter do
  describe "initialization" do
    before :each do
      @bucket = Riak::Bucket.allocate
      @key = 'key'
      allow(@bucket).to receive(:allow_mult).and_return(true)
      allow(@bucket).to receive(:client).and_return(double('client'))
      allow(@bucket).to receive('is_a?').and_return(true)
    end

    it "sets the bucket and key" do
      ctr = Riak::Counter.new @bucket, @key
      expect(ctr.bucket).to eq(@bucket)
      expect(ctr.key).to eq(@key)
    end

    it "requires allow_mult" do
      @bad_bucket = Riak::Bucket.allocate
      allow(@bad_bucket).to receive(:allow_mult).and_return(false)
      allow(@bad_bucket).to receive(:client).and_return(double('client'))

      expect{ctr = Riak::Counter.new @bad_bucket, @key}.to raise_error(ArgumentError)

    end
  end

  describe "incrementing and decrementing" do
    before :each do
      @backend = double 'backend'

      @client = double 'client'
      allow(@client).to receive(:backend).and_yield @backend

      @bucket = Riak::Bucket.allocate
      allow(@bucket).to receive(:allow_mult).and_return(true)
      allow(@bucket).to receive(:client).and_return(@client)

      @key = 'key'

      @ctr = Riak::Counter.new @bucket, @key

      @increment_expectation = proc{|n| expect(@backend).to receive(:post_counter).with(@bucket, @key, n, {})}
    end

    it "increments by 1 by default" do
      @increment_expectation[1]
      @ctr.increment
    end

    it "increments by positive numbers" do
      @increment_expectation[15]
      @ctr.increment 15
    end

    it "increments by negative numbers" do
      @increment_expectation[-12]
      @ctr.increment -12
    end

    it "decrements by 1 by default" do
      @increment_expectation[-1]
      @ctr.decrement
    end

    it "decrements by positive numbers" do
      @increment_expectation[-30]
      @ctr.decrement 30
    end

    it "decrements by negative numbers" do
      @increment_expectation[41]
      @ctr.decrement -41
    end

    it "forbids incrementing by non-integers" do
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
      allow(@bucket).to receive(:allow_mult).and_return(true)
      allow(@bucket).to receive(:client).and_return(@client)

      @key = 'key'

      @expect_post = expect(@backend).to receive(:post_counter).with(@bucket, @key, 1, {})

      @ctr = Riak::Counter.new @bucket, @key
    end

    it "doesn't retry on timeout" do
      @expect_post.once.and_raise('timeout')
      expect(proc { @ctr.increment }).to raise_error(RuntimeError)
    end

    it "doesn't retry on quorum failure" do
      @expect_post.once.and_raise('quorum not satisfied')
      expect(proc { @ctr.increment }).to raise_error(RuntimeError)
    end
  end
end
