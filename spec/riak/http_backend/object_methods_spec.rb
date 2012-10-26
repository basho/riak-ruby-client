require 'spec_helper'

describe Riak::Client::HTTPBackend::ObjectMethods do
  before :each do
    @client = Riak::Client.new
    @backend = Riak::Client::HTTPBackend.new(@client, @client.node)
    @bucket = Riak::Bucket.new(@client, "bucket")
    @object = Riak::RObject.new(@bucket, "bar")
    @backend.stub!(:new_scheme?).and_return(false)
  end

  describe "loading object data from the response" do
    it "should load the content type" do
      @backend.load_object(@object, {:headers => {"content-type" => ["application/json"]}})
      @object.content_type.should == "application/json"
    end

    it "should load the body data" do
      @backend.load_object(@object, {:headers => {"content-type" => ["application/json"]}, :body => '{"foo":"bar"}'})
      @object.raw_data.should be_present
      @object.data.should be_present
    end

    it "should handle raw data properly" do
      @object.should_not_receive(:deserialize) # optimize for the raw_data case, don't penalize people for using raw_data
      @backend.load_object(@object, {:headers => {"content-type" => ["application/json"]}, :body => body = '{"foo":"bar"}'})
      @object.raw_data.should == body
    end

    it "should deserialize the body data" do
      @backend.load_object(@object, {:headers => {"content-type" => ["application/json"]}, :body => "{}"})
      @object.data.should == {}
    end

    it "should leave the object data unchanged if the response body is blank" do
      @object.data = "Original data"
      @backend.load_object(@object, {:headers => {"content-type" => ["application/json"]}, :body => "", :code => 304})
      @object.data.should == "Original data"
    end

    it "should load the vclock from the headers" do
      @backend.load_object(@object, {:headers => {"content-type" => ["application/json"], 'x-riak-vclock' => ["somereallylongbase64string=="]}, :body => "{}"})
      @object.vclock.should == "somereallylongbase64string=="
    end

    it "should load links from the headers" do
      @backend.load_object(@object, {:headers => {"content-type" => ["application/json"], "link" => ['</riak/bar>; rel="up"']}, :body => "{}"})
      @object.links.should have(1).item
      @object.links.first.url.should == "/riak/bar"
      @object.links.first.rel.should == "up"
    end

    it "should load the ETag from the headers" do
      @backend.load_object(@object, {:headers => {"content-type" => ["application/json"], "etag" => ["32748nvas83572934"]}, :body => "{}"})
      @object.etag.should == "32748nvas83572934"
    end

    it "should load the modified date from the headers" do
      time = Time.now
      @backend.load_object(@object, {:headers => {"content-type" => ["application/json"], "last-modified" => [time.httpdate]}, :body => "{}"})
      @object.last_modified.to_s.should == time.to_s # bah, times are not equivalent unless equal
    end

    it "should load meta information from the headers" do
      @backend.load_object(@object, {:headers => {"content-type" => ["application/json"], "x-riak-meta-some-kind-of-robot" => ["for AWESOME"]}, :body => "{}"})
      @object.meta["some-kind-of-robot"].should == ["for AWESOME"]
    end

    it "should load indexes from the headers" do
      @backend.load_object(@object, {:headers => {"content-type" => ["application/json"], "x-riak-index-email_bin" => ["sean@basho.com"], "x-riak-index-rank_int" => ["50"]}, :body => "{}"})
      @object.indexes['email_bin'].should include('sean@basho.com')
      @object.indexes['rank_int'].should include(50)
    end

    it "should parse the location header into the key when present" do
      @backend.load_object(@object, {:headers => {"content-type" => ["application/json"], "location" => ["/riak/foo/baz"]}})
      @object.key.should == "baz"
    end

    it "should parse and escape the location header into the key when present" do
      @backend.load_object(@object, {:headers => {"content-type" => ["application/json"], "location" => ["/riak/foo/%5Bbaz%5D?vtag=1234"]}})
      @object.key.should == "[baz]"
    end

    context "when the response code is 300 and the content-type is multipart/mixed" do
      let(:http_response) { {:headers => {"content-type" => ["multipart/mixed; boundary=8XZD3w6ttFTHIz6LCmhVxn9Ex0K"]}, :code => 300, :body => File.read("spec/fixtures/multipart-basic-conflict.txt")} }
      let(:other_object) { Riak::RObject.new(@bucket, "bar2") }

      it 'marks the object as in conflict' do
        @backend.load_object(@object, http_response)
        @object.should be_conflict
      end

      it 'attempts to resolve the conflict' do
        @object.should respond_to(:attempt_conflict_resolution)
        @object.should_receive(:attempt_conflict_resolution).and_return(other_object)
        @backend.load_object(@object, http_response).should be(other_object)
      end
    end

    it "should unescape the key given in the location header" do
      @backend.load_object(@object, {:headers => {"content-type" => ["application/json"], "location" => ["/riak/foo/baz%20"]}})
      @object.key.should == "baz "
    end

    describe "extracting siblings" do
      before :each do
        @backend.load_object(@object, {:headers => {"x-riak-vclock" => ["merged"], "content-type" => ["multipart/mixed; boundary=8XZD3w6ttFTHIz6LCmhVxn9Ex0K"]}, :code => 300, :body => File.read("spec/fixtures/multipart-basic-conflict.txt")})
      end

      it "should extract the siblings" do
        @object.should have(2).siblings
        siblings = @object.siblings
        siblings[0].data.should == "bar"
        siblings[1].data.should == "foo"
      end
    end
  end

  describe "headers used for storing the object" do
    it "should include the content type" do
      @object.content_type = "application/json"
      @backend.store_headers(@object)["Content-Type"].should == "application/json"
    end

    it "should include the vclock when present" do
      @object.vclock = "123445678990"
      @backend.store_headers(@object)["X-Riak-Vclock"].should == "123445678990"
    end

    it "should exclude the vclock when nil" do
      @object.vclock = nil
      @backend.store_headers(@object).should_not have_key("X-Riak-Vclock")
    end

    describe "when conditional PUTs are requested" do
      before :each do
        @object.prevent_stale_writes = true
      end

      it "should include an If-None-Match: * header" do
        @backend.store_headers(@object).should have_key("If-None-Match")
        @backend.store_headers(@object)["If-None-Match"].should == "*"
      end

      it "should include an If-Match header with the etag when an etag is present" do
        @object.etag = "foobar"
        @backend.store_headers(@object).should have_key("If-Match")
        @backend.store_headers(@object)["If-Match"].should == @object.etag
      end
    end

    describe "when links are defined" do
      before :each do
        @object.links << Riak::Link.new("/riak/foo/baz", "next")
      end

      it "should include a Link header with references to other objects" do
        @backend.store_headers(@object).should have_key("Link")
        @backend.store_headers(@object)["Link"].should include('</riak/foo/baz>; riaktag="next"')
      end

      it "should exclude the 'up' link to the bucket from the header" do
        @object.links << Riak::Link.new("/riak/foo", "up")
        @backend.store_headers(@object).should have_key("Link")
        @backend.store_headers(@object)["Link"].should_not include('riaktag="up"')
      end

      context "when using the new URL scheme" do
        before { @backend.stub!(:new_scheme?).and_return(true) }

        it "should encode Links using the new format" do
          @backend.store_headers(@object).should have_key("Link")
          @backend.store_headers(@object)['Link'].should include('</buckets/foo/keys/baz>; riaktag="next"')
        end
      end
    end

    it "should exclude the Link header when no links are present" do
      @object.links = Set.new
      @backend.store_headers(@object).should_not have_key("Link")
    end

    describe "when meta fields are present" do
      before :each do
        @object.meta = {"some-kind-of-robot" => true, "powers" => "for awesome", "cold-ones" => 10}
      end

      it "should include X-Riak-Meta-* headers for each meta key" do
        @backend.store_headers(@object).should have_key("X-Riak-Meta-some-kind-of-robot")
        @backend.store_headers(@object).should have_key("X-Riak-Meta-cold-ones")
        @backend.store_headers(@object).should have_key("X-Riak-Meta-powers")
      end

      it "should turn non-string meta values into strings" do
        @backend.store_headers(@object)["X-Riak-Meta-some-kind-of-robot"].should == "true"
        @backend.store_headers(@object)["X-Riak-Meta-cold-ones"].should == "10"
      end

      it "should leave string meta values unchanged in the header" do
        @backend.store_headers(@object)["X-Riak-Meta-powers"].should == "for awesome"
      end
    end

    describe "when indexes are present" do
      before :each do
        @object.indexes = {"email_bin" => Set.new(['sean@basho.com', 'seancribbs@gmail.com']), "rank_int" => Set.new([50])}
      end

      it "should include X-Riak-Index-* headers for each index key" do
        @backend.store_headers(@object).should have_key('X-Riak-Index-email_bin')
        @backend.store_headers(@object).should have_key('X-Riak-Index-rank_int')
      end

      it "should join multi-valued indexes into a single header" do
        @backend.store_headers(@object)['X-Riak-Index-email_bin'].should == 'sean@basho.com, seancribbs@gmail.com'
      end

      it "should turn integer indexes into strings in the header" do
        @backend.store_headers(@object)['X-Riak-Index-rank_int'].should == '50'
      end
    end
  end

  describe "headers used for reloading the object" do
    it "should be blank when the etag and last_modified properties are blank" do
      @object.etag.should be_blank
      @object.last_modified.should be_blank
      @backend.reload_headers(@object).should be_blank
    end

    it "should include the If-None-Match key when the etag is present" do
      @object.etag = "etag!"
      @backend.reload_headers(@object)['If-None-Match'].should == "etag!"
    end

    it "should include the If-Modified-Since header when the last_modified time is present" do
      time = Time.now
      @object.last_modified = time
      @backend.reload_headers(@object)['If-Modified-Since'].should == time.httpdate
    end
  end
end
