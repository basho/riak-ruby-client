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

SingleCov.covered! if defined?(SingleCov)

describe Riak::Multiexist do
  before :each do
    @client = Riak::Client.new
    @bucket = Riak::Bucket.new(@client, 'foo')
    @pairs = [[@bucket, 'key1'], [@bucket, 'key2']]
  end

  it "returns state when only some objects are found" do
    expect(@bucket).to receive(:exists?).
      with('key1').
      and_return(false)

    expect(@bucket).to receive(:exists?).
      with('key2').
      and_return(true)

    results = Riak::Multiexist.perform @client, @pairs

    expect(results[[@bucket, 'key1']]).to eq false
    expect(results[[@bucket, 'key2']]).to eq true
  end

  it "fails when checking the key produces an error" do
    expect(@bucket).to receive(:exists?).
      with(satisfy { |key| %w(key1 key2).include?(key) }).
      and_raise(Riak::ProtobuffsFailedRequest.new(:whoops, "whoops")).
      at_least(1) # race condition ... both threads can read at the same time

    expect { Riak::Multiexist.perform @client, @pairs }.to raise_error(Riak::ProtobuffsFailedRequest)
  end
end
