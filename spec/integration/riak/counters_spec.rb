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
require 'riak'

describe Riak::Counter, test_client: true, integration: true do
  before :all do
    @bucket = random_bucket 'counter_spec'
    @bucket.allow_mult = true

    @counter = Riak::Counter.new @bucket, 'counter_spec'
  end

  it 'reads and updates' do
    initial = @counter.value

    @counter.increment
    @counter.increment

    expect(@counter.value).to eq(initial + 2)

    @counter.decrement 2

    expect(@counter.value).to eq(initial)

    5.times do
      amt = rand(10_000)

      @counter.increment amt
      expect(@counter.value).to eq(initial + amt)

      @counter.decrement (amt * 2)
      expect(@counter.value).to eq(initial - amt)

      expect(@counter.increment_and_return(amt)).to eq(initial)
    end
  end
end
