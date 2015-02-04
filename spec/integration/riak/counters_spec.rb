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
