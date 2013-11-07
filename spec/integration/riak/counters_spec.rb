require 'spec_helper'
require 'riak'

describe Riak::Counter, test_client: true, integration: true do
  before :all do
    @bucket = random_bucket 'counter_spec'
    @bucket.allow_mult = true

    @counter = Riak::Counter.new @bucket, 'counter_spec'
  end

  it 'should read and update' do
    initial = @counter.value

    @counter.increment
    @counter.increment

    @counter.value.should == (initial + 2)

    @counter.decrement 2

    @counter.value.should == initial

    5.times do
      amt = rand(10_000)
      
      @counter.increment amt
      @counter.value.should == (initial + amt)

      @counter.decrement (amt * 2)
      @counter.value.should == (initial - amt)

      @counter.increment_and_return(amt).should == initial
    end
  end
end
