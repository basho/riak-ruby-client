require 'spec_helper'
require 'riak'

describe Riak::Counter, test_server: true, slow: true do
  before :all do
    @client = Riak::Client.new(http_port: test_server.http_port,
                               pb_port: test_server.pb_port
                               )

    @counter = Riak::Counter.new @client['counter_spec'], 'counter_spec'
  end


  ['pbc', 'http'].each do |protocol|
    describe protocol do
      before :all do
        @client.protocol = protocol
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
  end
end
