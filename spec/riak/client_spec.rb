require 'spec_helper'

describe Riak::Client, test_client: true do
  describe "when initializing" do
    it "should default a single local node" do
      client = Riak::Client.new
      expect(client.nodes).to eq([Riak::Client::Node.new(client)])
    end

    it "should accept a host" do
      client = Riak::Client.new :host => "riak.basho.com"
      expect(client.nodes.size).to eq(1)
      expect(client.nodes.first.host).to eq("riak.basho.com")
    end

    it "should accept a Protobuffs port" do
      client = Riak::Client.new :pb_port => 9000
      expect(client.nodes.size).to eq(1)
      expect(client.nodes.first.pb_port).to eq(9000)
    end

    it "should accept a client ID" do
      client = Riak::Client.new :client_id => "AAAAAA=="
      expect(client.client_id).to eq("AAAAAA==")
    end

    it "should create a client ID if not specified" do
      expect(Riak::Client.new(pb_port: test_client.nodes.first.pb_port).client_id).not_to be_nil
    end
  end

  it "should expose a Stamp object" do
    expect(subject).to respond_to(:stamp)
    expect(subject.stamp).to be_kind_of(Riak::Stamp)
  end

  describe "reconfiguring" do
    before :each do
      @client = Riak::Client.new
    end

    describe "setting the client id" do
      it "should accept a string unmodified" do
        @client.client_id = "foo"
        expect(@client.client_id).to eq("foo")
      end

      it "should reject an integer equal to the maximum client id" do
        expect { @client.client_id = Riak::Client::MAX_CLIENT_ID }.to raise_error(ArgumentError)
      end

      it "should reject an integer larger than the maximum client id" do
        expect { @client.client_id = Riak::Client::MAX_CLIENT_ID + 1 }.to raise_error(ArgumentError)
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
        expect(p).to be_instance_of(Riak::Client::BeefcakeProtobuffsBackend)
      end
    end

    it "should teardown the existing Protobuffs connections when changed" do
      expect(@client.protobuffs_pool).to receive(:clear)
      @client.protobuffs_backend = :Beefcake
    end

    it "should raise an error when the chosen backend is not valid" do
      expect(Riak::Client::BeefcakeProtobuffsBackend).to receive(:configured?).and_return(false)
      expect { @client.protobuffs { |x| } }.to raise_error
    end
  end

  describe "choosing a unified backend" do
    before :each do
      @client = Riak::Client.new
    end

    it "should use Protobuffs when the protocol is pbc" do
      @client.backend do |b|
        expect(b).to be_kind_of(Riak::Client::ProtobuffsBackend)
      end
    end
  end

  describe "retrieving many values" do
    before :each do
      @client = Riak::Client.new
      @bucket = @client.bucket('foo')
      expect(@bucket).to receive(:[]).with('value1').and_return(double('robject'))
      expect(@bucket).to receive(:[]).with('value2').and_return(double('robject'))
      @pairs = [
        [@bucket, 'value1'],
        [@bucket, 'value2']
      ]
    end

    it 'should accept an array of bucket and key pairs' do
      expect{ @client.get_many(@pairs) }.not_to raise_error
    end

    it 'should return a hash of bucket/key pairs and robjects' do
      @results = @client.get_many(@pairs)
      expect(@results).to be_a Hash
      expect(@results.length).to be(@pairs.length)
    end
  end

  describe "retrieving a bucket" do
    before :each do
      @client = Riak::Client.new
      @backend = double("Backend")
      allow(@client).to receive(:backend).and_yield(@backend)
    end

    it "should return a bucket object" do
      expect(@client.bucket("foo")).to be_kind_of(Riak::Bucket)
    end

    it "should fetch bucket properties if asked" do
      expect(@backend).to receive(:get_bucket_props) {|b| expect(b.name).to eq("foo"); {} }
      @client.bucket("foo", :props => true)
    end

    it "should memoize bucket parameters" do
      @bucket = double("Bucket")
      expect(Riak::Bucket).to receive(:new).with(@client, "baz").once.and_return(@bucket)
      expect(@client.bucket("baz")).to eq(@bucket)
      expect(@client.bucket("baz")).to eq(@bucket)
    end

    it "should reject buckets with zero-length names" do
      expect { @client.bucket('') }.to raise_error(ArgumentError)
    end
  end

  describe "listing buckets" do
    before do
      @client = Riak::Client.new
      @backend = double("Backend")
      allow(@client).to receive(:backend).and_yield(@backend)
    end

    after { Riak.disable_list_keys_warnings = true }

    it "should list buckets" do
      expect(@backend).to receive(:list_buckets).and_return(%w{test test2})
      buckets = @client.buckets
      expect(buckets.size).to eq(2)
      expect(buckets).to be_all {|b| b.is_a?(Riak::Bucket) }
      expect(buckets[0].name).to eq("test")
      expect(buckets[1].name).to eq("test2")
    end

    it "should warn about the expense of list-buckets when warnings are not disabled" do
      Riak.disable_list_keys_warnings = false
      allow(@backend).to receive(:list_buckets).and_return(%w{test test2})
      expect(@client).to receive(:warn)
      @client.buckets
    end

    it "should support a timeout option" do
      expect(@backend).to receive(:list_buckets).with(timeout: 1234).and_return(%w{test test2})

      buckets = @client.buckets timeout: 1234
      expect(buckets.size).to eq(2)
    end
  end
end
