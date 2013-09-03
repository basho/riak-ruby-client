require 'spec_helper'

describe Riak::Client do
  describe "when initializing" do
    it "should default a single local node" do
      client = Riak::Client.new
      client.nodes.should == [Riak::Client::Node.new(client)]
    end

    it "should accept a host" do
      client = Riak::Client.new :host => "riak.basho.com"
      client.nodes.size.should == 1
      client.nodes.first.host.should == "riak.basho.com"
    end

    it "should accept a Protobuffs port" do
      client = Riak::Client.new :pb_port => 9000
      client.nodes.size.should == 1
      client.nodes.first.pb_port.should == 9000
    end

    it "should accept a client ID" do
      client = Riak::Client.new :client_id => "AAAAAA=="
      client.client_id.should == "AAAAAA=="
    end

    it "should create a client ID if not specified" do
      Riak::Client.new(pb_port: 10017).client_id.should_not be_nil
    end
  end

  it "should expose a Stamp object" do
    subject.should respond_to(:stamp)
    subject.stamp.should be_kind_of(Riak::Stamp)
  end

  describe "reconfiguring" do
    before :each do
      @client = Riak::Client.new
    end

    describe "setting the client id" do
      it "should accept a string unmodified" do
        @client.client_id = "foo"
        @client.client_id.should == "foo"
      end

      it "should reject an integer equal to the maximum client id" do
        lambda { @client.client_id = Riak::Client::MAX_CLIENT_ID }.should raise_error(ArgumentError)
      end

      it "should reject an integer larger than the maximum client id" do
        lambda { @client.client_id = Riak::Client::MAX_CLIENT_ID + 1 }.should raise_error(ArgumentError)
      end
    end
  end

  describe "choosing a Protobuffs backend" do
    before :each do
      @client = Riak::Client.new
    end

    it "should choose the selected backend" do
      @client.protobuffs_backend = :Beefcake
      @client.protobuffs do |p|
        p.should be_instance_of(Riak::Client::BeefcakeProtobuffsBackend)
      end
    end

    it "should teardown the existing Protobuffs connections when changed" do
      @client.protobuffs_pool.should_receive(:clear)
      @client.protobuffs_backend = :Beefcake
    end

    it "should raise an error when the chosen backend is not valid" do
      Riak::Client::BeefcakeProtobuffsBackend.should_receive(:configured?).and_return(false)
      lambda { @client.protobuffs { |x| } }.should raise_error
    end
  end

  describe "choosing a unified backend" do
    before :each do
      @client = Riak::Client.new
    end

    it "should use Protobuffs when the protocol is pbc" do
      @client.backend do |b|
        b.should be_kind_of(Riak::Client::ProtobuffsBackend)
      end
    end
  end

  describe "retrieving many values" do
    before :each do
      @client = Riak::Client.new
      @bucket = @client.bucket('foo')
      @bucket.should_receive(:[]).with('value1').and_return(mock('robject'))
      @bucket.should_receive(:[]).with('value2').and_return(mock('robject'))
      @pairs = [
        [@bucket, 'value1'],
        [@bucket, 'value2']
      ]
    end

    it 'should accept an array of bucket and key pairs' do
      lambda{ @client.get_many(@pairs) }.should_not raise_error
    end

    it 'should return a hash of bucket/key pairs and robjects' do
      @results = @client.get_many(@pairs)
      @results.should be_a Hash
      @results.length.should be(@pairs.length)
    end
  end

  describe "retrieving a bucket" do
    before :each do
      @client = Riak::Client.new
      @backend = mock("Backend")
      @client.stub!(:backend).and_yield(@backend)
    end

    it "should return a bucket object" do
      @client.bucket("foo").should be_kind_of(Riak::Bucket)
    end

    it "should fetch bucket properties if asked" do
      @backend.should_receive(:get_bucket_props) {|b| b.name.should == "foo"; {} }
      @client.bucket("foo", :props => true)
    end

    it "should memoize bucket parameters" do
      @bucket = mock("Bucket")
      Riak::Bucket.should_receive(:new).with(@client, "baz").once.and_return(@bucket)
      @client.bucket("baz").should == @bucket
      @client.bucket("baz").should == @bucket
    end

    it "should reject buckets with zero-length names" do
      expect { @client.bucket('') }.to raise_error(ArgumentError)
    end
  end

  describe "listing buckets" do
    before do
      @client = Riak::Client.new
      @backend = mock("Backend")
      @client.stub!(:backend).and_yield(@backend)
    end

    after { Riak.disable_list_keys_warnings = true }

    it "should list buckets" do
      @backend.should_receive(:list_buckets).and_return(%w{test test2})
      buckets = @client.buckets
      buckets.should have(2).items
      buckets.should be_all {|b| b.is_a?(Riak::Bucket) }
      buckets[0].name.should == "test"
      buckets[1].name.should == "test2"
    end

    it "should warn about the expense of list-buckets when warnings are not disabled" do
      Riak.disable_list_keys_warnings = false
      @backend.stub!(:list_buckets).and_return(%w{test test2})
      @client.should_receive(:warn)
      @client.buckets
    end

    it "should support a timeout option" do
      @backend.should_receive(:list_buckets).with(timeout: 1234).and_return(%w{test test2})

      buckets = @client.buckets timeout: 1234
      buckets.should have(2).items
    end
  end
end
