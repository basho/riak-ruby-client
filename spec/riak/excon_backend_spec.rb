require 'spec_helper'

begin
  require 'excon'
rescue LoadError
  warn "Skipping ExconBackend specs, excon library not found."
else
  $mock_server = DrbMockServer
  $mock_server.maybe_start

  describe Riak::Client::ExconBackend do
    def setup_http_mock(method, uri, options={})
      method  = method.to_s.upcase
      uri     = URI.parse(uri)
      path    = uri.path          || "/"
      query   = uri.query         || ""
      body    = options[:body]    || []
      headers = options[:headers] || {}
      headers['Content-Type']     ||= "text/plain"
      status  = options[:status] ? Array(options[:status]).first.to_i : 200
      @_mock_set = [status, headers, method, path, query, body]
      $mock_server.expect(*@_mock_set)
    end

    before :each do
      @client = Riak::Client.new(:http_port => $mock_server.port, :http_backend => :Excon) # Point to our mock
      @node = @client.node
      @backend = @client.new_http_backend if described_class.configured?
      @_mock_set = false
    end

    after :each do
      if @_mock_set
        $mock_server.satisfied.should be_true #("Expected #{@_mock_set.inspect}, failed")
      end
    end

    it_should_behave_like "HTTP backend"

    it "should split long headers into 8KB chunks" do
      # TODO: This doesn't actually inspect the emitted headers. How
      # can it?
      setup_http_mock(:put, @backend.path("/riak/","foo").to_s, :body => "ok")
      lambda do
        @backend.put(200, @backend.path("/riak", "foo"), "body", {"Long-Header" => (["12345678"*10]*100).join(", ") })
      end.should_not raise_error
    end

    it "should support IO objects as the request body on PUT" do
      File.open(File.expand_path("../../fixtures/cat.jpg", __FILE__), 'rb') do |file|
        lambda do
          setup_http_mock(:put, @backend.path("/riak/","foo").to_s, :body => "ok")
          @backend.put(200, @backend.path("/riak/","foo"), file)
          $mock_server.satisfied.should be_true
        end.should_not raise_error
      end
    end

    it "should support IO objects as the request body on POST" do
      File.open(File.expand_path("../../fixtures/cat.jpg", __FILE__), 'rb') do |file|
        lambda do
          setup_http_mock(:post, @backend.path("/riak/","foo").to_s, :body => "ok")
          @backend.post(200, @backend.path("/riak/", "foo"), file)
          $mock_server.satisfied.should be_true
        end.should_not raise_error
      end
    end

    context "checking the Excon Gem version" do
      subject { described_class }

      def suppress_warnings
        original_verbosity = $VERBOSE
        $VERBOSE = nil
        result =  yield
        $VERBOSE = original_verbosity
        return result
      end

      def set_excon_version(v)
        original_version = Excon::VERSION
        suppress_warnings { Excon.const_set(:VERSION, v) }
        yield
        suppress_warnings {Excon.const_set(:VERSION, original_version)}
      end

      context "when it meets the minimum requirement" do
        it { should be_configured }

        context "and has a version number that is not *lexically* greater than the minimum version" do
          around {|ex| set_excon_version("0.13.2", &ex) }
          it { should be_configured }
        end
      end

      context "when it does not meet the minimum requirement" do
        around {|ex| set_excon_version("0.5.6", &ex) }
        it { should_not be_configured }
      end
    end
  end
end
