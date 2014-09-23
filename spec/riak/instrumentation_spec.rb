require 'spec_helper'

describe Riak::Client do

  before do
    @client = Riak::Client.new
    @backend = mock("Backend")
    @client.stub!(:backend).and_yield(@backend)
    @client.stub!(:http).and_yield(@backend)
    @bucket = Riak::Bucket.new(@client, "foo")

    @events = []
    @notifier = ActiveSupport::Notifications.notifier
    @notifier.subscribe { |*args| (@events ||= []) << event(*args) }
  end

  describe "instrumentation", instrumentation: true do

    it "should notify on the 'buckets' operation" do
      @backend.should_receive(:list_buckets).and_return(%w{test test2})
      test_client_event(@client, 'riak.list_buckets') do
        @client.buckets
      end
    end

    it "should notify on the 'list_buckets' operation" do
      @backend.should_receive(:list_buckets).and_return(%w{test test2})
      test_client_event(@client, 'riak.list_buckets') do
        @client.list_buckets
      end
    end

    it "should notify on the 'list_keys' operation" do
      @backend.should_receive(:list_keys).and_return(%w{test test2})
      test_client_event(@client, 'riak.list_keys') do
        @client.list_keys(@bucket)
      end
    end

    it "should notify on the 'get_bucket_props' operation" do
      @backend.should_receive(:get_bucket_props).and_return({})
      test_client_event(@client, 'riak.get_bucket_props') do
        @client.get_bucket_props(@bucket)
      end
    end

    it "should notify on the 'set_bucket_props' operation" do
      @backend.should_receive(:set_bucket_props).and_return({})
      test_client_event(@client, 'riak.set_bucket_props') do
        @client.set_bucket_props(@bucket, {})
      end
    end

    it "should notify on the 'clear_bucket_props' operation" do
      @backend.should_receive(:clear_bucket_props).and_return({})
      test_client_event(@client, 'riak.clear_bucket_props') do
        @client.clear_bucket_props(@bucket)
      end
    end

    it "should notify on the 'get_index' operation" do
      @backend.should_receive(:get_index).and_return({})
      test_client_event(@client, 'riak.get_index') do
        @client.get_index(@bucket, 'index', 'query', {})
      end
    end

    it "should notify on the 'get_object' operation" do
      @backend.should_receive(:fetch_object).and_return(nil)
      test_client_event(@client, 'riak.get_object') do
        @client.get_object(@bucket, 'bar')
      end
    end

    it "should notify on the 'store_object' operation" do
      @backend.should_receive(:store_object).and_return(nil)
      test_client_event(@client, 'riak.store_object') do
        @client.store_object(Object.new)
      end
    end

    it "should notify on the 'reload_object' operation" do
      @backend.should_receive(:reload_object).and_return(nil)
      test_client_event(@client, 'riak.reload_object') do
        @client.reload_object(Object.new)
      end
    end

    it "should notify on the 'delete_object' operation" do
      @backend.should_receive(:delete_object).and_return(nil)
      test_client_event(@client, 'riak.delete_object') do
        @client.delete_object(@bucket, 'bar')
      end
    end

    it "should notify on the 'store_file' operation" do
      @backend.should_receive(:store_file).and_return(nil)
      test_client_event(@client, 'riak.store_file') do
        @client.store_file('filename')
      end
    end

    it "should notify on the 'get_file' operation" do
      @backend.should_receive(:get_file).and_return(nil)
      test_client_event(@client, 'riak.get_file') do
        @client.get_file('filename')
      end
    end

    it "should notify on the 'delete_file' operation" do
      @backend.should_receive(:delete_file).and_return(nil)
      test_client_event(@client, 'riak.delete_file') do
        @client.delete_file('filename')
      end
    end

    it "should notify on the 'file_exists' operation" do
      @backend.should_receive(:file_exists?).and_return(nil)
      test_client_event(@client, 'riak.file_exists') do
        @client.file_exists?('filename')
      end
    end

    it "should notify on the 'file_exist' operation" do
      @backend.should_receive(:file_exists?).and_return(nil)
      test_client_event(@client, 'riak.file_exists') do
        @client.file_exist?('filename')
      end
    end

    it "should notify on the 'link_walk' operation" do
      @backend.should_receive(:link_walk).and_return(nil)
      test_client_event(@client, 'riak.link_walk') do
        @client.link_walk(Object.new, [Riak::WalkSpec.new(:bucket => 'foo')])
      end
    end

    it "should notify on the 'mapred' operation" do
      @mapred = Riak::MapReduce.new(@client).add('test').map("function(){}").map("function(){}")
      @backend.should_receive(:mapred).and_return(nil)
      test_client_event(@client, 'riak.map_reduce') do
        @client.mapred(@mapred)
      end
    end

    it "should notify on the 'ping' operation" do
      @backend.should_receive(:ping).and_return(nil)
      test_client_event(@client, 'riak.ping') do
        @client.ping
      end
    end
  end
end

def test_client_event(client, event_name, &block)
  block.call
  @events.size.should == 1
  event = @events.first
  event.name.should == event_name
  event.payload[:protocol].should == client.protocol
  event.payload[:client_id].should == client.client_id
end

# name, start, finish, id, payload
def event(*args)
  ActiveSupport::Notifications::Event.new(*args)
end
