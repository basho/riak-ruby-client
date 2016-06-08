shared_examples_for "Unified backend API" do
  # ping
  it "pings the server" do
    expect(@backend.ping).to be_truthy
  end

  it "gets info about the server" do
    expect{ @backend.server_info }.to_not raise_error

    expect(@backend.server_info).to include(:node, :server_version)
  end

  it "gets client id" do
    expect{ @backend.get_client_id }.to_not raise_error

    expect(@backend.get_client_id).to be_a String
  end

  # fetch_object
  context "fetching an object" do
    before do
      @robject = Riak::RObject.new(@bucket, "fetch")
      @robject.content_type = "application/json"
      @robject.data = { "test" => "pass" }
      @robject.indexes['test_bin'] << 'pass'
      @robject.links << Riak::Link.new('/riak/foo/bar', 'next')
      @robject.links << Riak::Link.new('/riak/foo/baz', 'next')
      @backend.store_object(@robject)
    end

    it "finds a stored object" do
      robj = @backend.fetch_object(@bucket.name, "fetch")
      expect(robj).to be_kind_of(Riak::RObject)
      expect(robj.data).to eq({ "test" => "pass" })
      expect(robj.links).to be_a Set
    end

    it "raises an error when the object is not found" do
      begin
        @backend.fetch_object(@bucket.name, "notfound")
      rescue Riak::FailedRequest => exception
        @exception = exception
      end
      expect(@exception).to be_kind_of(Riak::FailedRequest)
      expect(@exception).to be_not_found
    end

    [1, 2, 3, :one, :quorum, :all, :default].each do |q|
      it "accepts a R value of #{q.inspect} for the request" do
        robj = @backend.fetch_object(@bucket.name, "fetch", :r => q)
        expect(robj).to be_kind_of(Riak::RObject)
        expect(robj.data).to eq({ "test" => "pass" })
      end

      it "accepts a PR value of #{q.inspect} for the request" do
        robj = @backend.fetch_object(@bucket.name, "fetch", :pr => q)
        expect(robj).to be_kind_of(Riak::RObject)
        expect(robj.data).to eq({ "test" => "pass" })
      end
    end

    it "marshals indexes properly", :retries => 5 do
      robj = @backend.fetch_object(@bucket.name, 'fetch')
      expect(robj.indexes['test_bin']).to be
      expect(robj.indexes['test_bin']).to include('pass')
    end
  end

  # reload_object
  context "reloading an existing object" do
    before do
      @robject = Riak::RObject.new(@bucket, 'reload')
      @robject.content_type = "application/json"
      @robject.data = {"test" => "pass"}
      @backend.store_object(@robject)
      @robject2 = @backend.fetch_object(@bucket.name, "reload")
      @robject2.data["test"] = "second"
      @backend.store_object(@robject2, :returnbody => true)
    end

    it "modifies the object with the reloaded data" do
      @backend.reload_object(@robject)
    end

    [1, 2, 3, :one, :quorum, :all, :default].each do |q|
      it "accepts a valid R value of #{q.inspect} for the request" do
        @backend.reload_object(@robject, :r => q)
      end

      it "accepts a valid PR value of #{q.inspect} for the request" do
        @backend.reload_object(@robject, :pr => q)
      end
    end

    after do |example|
      unless example.pending?
        expect(@robject.vclock).to eq(@robject2.vclock)
        expect(@robject.data['test']).to eq("second")
      end
    end
  end

  # store_object
  context "storing an object" do
    before do
      @robject = Riak::RObject.new(@bucket, random_key)
      @robject.content_type = "application/json"
      @robject.data = {"test" => "pass"}
    end

    it "saves the object" do
      @backend.store_object(@robject)
    end

    it "modifies the object with the returned data if returnbody" do
      @backend.store_object(@robject, :returnbody => true)
      expect(@robject.vclock).to be_present
    end

    [1, 2, 3, :one, :quorum, :all, :default].each do |q|
      it "accepts a W value of #{q.inspect} for the request" do
        @backend.store_object(@robject, :returnbody => false, :w => q)
        expect(@bucket.exists?(@robject.key)).to be_truthy
      end

      it "accepts a DW value of #{q.inspect} for the request" do
        @backend.store_object(@robject, :returnbody => false, :w => :all, :dw => q)
      end

      it "accepts a PW value of #{q.inspect} for the request" do
        @backend.store_object(@robject, :returnbody => false, :pw => q)
      end
    end

    it "stores an object with indexes" do
      @robject.indexes['foo_bin'] << 'bar'
      @backend.store_object(@robject, :returnbody => true)
      expect(@robject.indexes).to include('foo_bin')
      expect(@robject.indexes['foo_bin']).to include('bar')
    end

    after do
      expect { @backend.fetch_object(@bucket.name, @robject.key) }.not_to raise_error
    end
  end

  # delete_object
  context "deleting an object" do
    before do
      @obj = Riak::RObject.new(@client.bucket("test"), "delete")
      @obj.content_type = "application/json"
      @obj.data = [1]
      @backend.store_object(@obj)
    end

    it "removes the object" do
      @backend.delete_object("test", "delete")
      expect(@obj.bucket.exists?("delete")).to be_falsey
    end

    [1, 2, 3, :one, :quorum, :all, :default].each do |q|
      it "accepts an RW value of #{q.inspect} for the request" do
        @backend.delete_object("test", "delete", :rw => q)
      end
    end

    it "accepts a vclock value for the request" do
      @backend.delete_object("test", "delete", :vclock => @obj.vclock)
    end

    after do
      expect(@obj.bucket.exists?("delete")).to be_falsey
    end
  end

  # get_bucket_props
  context "fetching bucket properties" do
    it "fetches a hash of bucket properties" do
      props = @backend.get_bucket_props("test")
      expect(props).to be_kind_of(Hash)
      expect(props).to include("n_val")
    end
  end

  # set_bucket_props
  context "setting bucket properties" do
    it "stores properties for the bucket" do
      @backend.set_bucket_props("test", {"n_val" => 3})
      expect(@backend.get_bucket_props("test")["n_val"]).to eq(3)
    end
  end

  # list_keys
  context "listing keys in a bucket" do
    before do
      @list_bucket = random_bucket 'unified_backend_list_keys'
      obj = Riak::RObject.new(@list_bucket, "keys")
      obj.content_type = "application/json"
      obj.data = [1]
      @backend.store_object(obj)
    end

    it "fetches an array of string keys" do
      expect(@backend.list_keys(@list_bucket)).to eq(["keys"])
    end

    context "streaming through a block" do
      it "handles a large number of keys" do
        obj = Riak::RObject.new(@list_bucket)
        obj.content_type = "application/json"
        obj.data = [1]
        750.times do |i|
          obj.key = i.to_s
          obj.store(:w => 1, :dw => 0, :returnbody => false)
        end
        @backend.list_keys(@list_bucket) do |keys|
          expect(keys).to be_all {|k| k == 'keys' || (0..749).include?(k.to_i) }
        end
      end

      it "passes an array of keys to the block" do
        @backend.list_keys(@list_bucket) do |keys|
          expect(keys).to eq(["keys"]) unless keys.empty?
        end
      end

      it "allows requests issued inside the block to execute" do
        errors = []
        @backend.list_keys(@list_bucket) do |keys|
          keys.each do |key|
            begin
              @client.get_object(@list_bucket, key)
            rescue => e
              errors << e
            end
          end
        end
        expect(errors).to be_empty
      end
    end
  end

  # list_buckets
  context "listing buckets" do
    before do
      obj = Riak::RObject.new(@client.bucket("test"), "buckets")
      obj.content_type = "application/json"
      obj.data = [1]
      @backend.store_object(obj)
    end

    it "fetches a list of string bucket names" do
      list = @backend.list_buckets
      expect(list).to be_kind_of(Array)
      expect(list).to include("test")
    end
  end

  # get_index
  context "querying secondary indexes" do
    before do
      50.times do |i|
        @client.bucket('test').new(i.to_s).tap do |obj|
          obj.indexes["index_int"] << i
          obj.data = [i]
          @backend.store_object(obj)
        end
      end
    end

    it "finds keys for an equality query" do
      expect(@backend.get_index('test', 'index_int', 20)).to eq(["20"])
    end

    it "finds keys for a range query" do
      expect(@backend.get_index('test', 'index_int', 19..21)).to match_array(%w(19 20 21))
    end

    it "returns an empty array for a query that does not match any keys" do
      expect(@backend.get_index('test', 'index_int', 10000)).to eq([])
    end
  end

  # mapred
  context "performing MapReduce" do
    before do
      @mapred_bucket = random_bucket("mapred_test")
      obj = Riak::RObject.new(@mapred_bucket, "1")
      obj.content_type = "application/json"
      obj.data = {"value" => "1" }
      @backend.store_object(obj)
      @mapred = Riak::MapReduce.new(@client).
        add(@mapred_bucket.name).
        map("Riak.mapValuesJson", :keep => true)
    end

    it "doesn't raise an error without phases" do
      @mapred.query.clear
      @backend.mapred(@mapred)
    end

    it "performs a simple MapReduce request" do
      expect(@backend.mapred(@mapred)).to eq([{"value" => "1"}])
    end

    it "returns an ordered array of results when multiple phases are kept" do
      @mapred.reduce("function(objects){ return objects; }", :keep => true)
      expect(@backend.mapred(@mapred)).to eq([[{"value" => "1"}], [{"value" => "1"}]])
    end

    it "doesn't remove empty phase results when multiple phases are kept" do
      @mapred.reduce("function(){ return []; }", :keep => true)
      expect(@backend.mapred(@mapred)).to eq([[{"value" => "1"}], []])
    end

    context "streaming results through a block" do
      it "passes phase number and result to the block" do
        @backend.mapred(@mapred) do |phase, result|
          unless result.empty?
            expect(phase).to eq(0)
            expect(result).to eq([{"value" => "1"}])
          end
        end
      end

      it "allows requests issued inside the block to execute" do
        errors = []
        @backend.mapred(@mapred) do |phase, result|
          unless result.empty?
            result.each do |v|
              begin
                @client.get_object(@mapred_bucket, v['value'])
              rescue => e
                errors << e
              end
            end
          end
        end
        expect(errors).to be_empty
      end
    end
  end

  # search
  context "searching fulltext indexes" do
    # Search functionality existed since Riak 0.13, but PBC only
    # entered into the picture in 1.2. PBC can support searches
    # against 1.1 and earlier nodes using MapReduce emulation, but has
    # limited functionality. We'll enter separate tests for the
    # pre-1.2 functionality.
    include_context "search corpus setup"

    it 'finds indexed documents, returning ids' do
      results = @backend.search @search_bucket.name, 'predictable operations behavior', fl: '_yz_rk', df: 'text'
      expect(results).to have_key 'docs'
      expect(results).to have_key 'max_score'
      expect(results).to have_key 'num_found'

      found = results['docs'].any? do |e|
        e['_yz_rk'] == 'bitcask-10'
      end

      expect(found).to be_truthy
    end

    it 'finds indexed documents, returning documents' do
      # For now use '*' until #122 is merged into riak_search
      results = @backend.search @search_bucket.name, 'predictable operations behavior', fl: '_yz_rk', df: 'text'
      expect(results).to have_key 'docs'
      expect(results).to have_key 'max_score'
      expect(results).to have_key 'num_found'

      found = results['docs'].any? do |e|
        e['_yz_rk'] == 'bitcask-10'
      end

      expect(found).to be_truthy
    end
  end

  # gzip
  context "using gzip" do
    before do
      @robject = Riak::RObject.new(@bucket, "fetch")
      @robject.content_type = "application/json"
      @robject.content_encoding = "gzip"
      @robject.data = { "test" => "pass" }
      @backend.store_object(@robject)
    end

    it "stores a compressed object" do
      expected_data = @robject.deserialize(@robject.decompress(@robject.raw_data))
      expect(expected_data).to eq(@robject.data)
    end

    it "loads a compressed object" do
      robj = @backend.fetch_object(@bucket.name, "fetch")
      expect(robj).to be_kind_of(Riak::RObject)
      expect(robj.data).to eq(@robject.data)
    end
  end
end
