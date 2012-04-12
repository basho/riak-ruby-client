require 'spec_helper'

describe "HTTP" do
  before do
    @web_port = $test_server.http_port
    @client = Riak::Client.new(:http_port => @web_port)
  end

  [:ExconBackend, :NetHTTPBackend].each do |klass|
    bklass = Riak::Client.const_get(klass)
    if bklass.configured?
      describe klass.to_s do
        before do
          @backend = bklass.new(@client, @client.node)
        end

        it_should_behave_like "Unified backend API"

        describe "using Luwak", :version => "0.14.0".."1.0.3" do
          let(:file) { File.open(__FILE__) }
          let(:key) { "spec.rb" }
          let(:string) { file.read }

          def retry_400
            begin
              yield
            rescue Riak::HTTPFailedRequest => e
              # Riak 1.0.x (and possibly earlier) has a bug in
              # mochiweb that will sometimes leave dangling 400
              # responses on the wire between requests when the
              # connection is left open. This will happen sometimes
              # immediately after a store_file request.
              if e.code == 400
                retry
              else
                raise
              end
            end
          end

          it "should store an IO with a given key" do
            @backend.store_file(key, 'text/plain', file)
            stored_file = retry_400 { @backend.get_file(key) }
            stored_file.content_type.should == 'text/plain'
            stored_file.size.should == file.size
          end

          it "should store a String with a given key" do
            @backend.store_file(key, 'text/plain', string)
            stored_file = retry_400 { @backend.get_file(key) }
            stored_file.content_type.should == 'text/plain'
            stored_file.size.should == string.bytesize
          end

          it "should store an IO with a server-defined key" do
            key = @backend.store_file('text/plain', file)
            stored_file = retry_400 { @backend.get_file(key) }
            stored_file.content_type.should == 'text/plain'
            stored_file.size.should == file.size
          end

          it "should store a String with a server-defined key" do
            key = @backend.store_file('text/plain', string)
            stored_file = retry_400 { @backend.get_file(key) }
            stored_file.content_type.should == 'text/plain'
            stored_file.size.should == string.bytesize
          end
        end
      end
    end
  end

  class Reader < Array
    def read(*args)
      shift
    end

    def size
      join.size
    end
  end

  class SizelessReader < Reader
    undef :size
  end

  describe 'NetHTTPBackend' do
    subject { Riak::Client::NetHTTPBackend.new(@client, @client.node) }
    let(:file) { File.open(__FILE__) }
    let(:sized) { Reader.new(["foo", "bar", "baz"]) }
    let(:sizeless) { SizelessReader.new(["foo", "bar", "baz"]) }
    it "should set the content-length or transfer-encoding properly on IO uploads" do
      lambda { subject.put(204, subject.object_path('nethttp', 'test-file'), file, {"Content-Type" => "text/plain"}) }.should_not raise_error
      lambda { subject.put(204, subject.object_path('nethttp', 'test-sized'), sized, {"Content-Type" => "text/plain"}) }.should_not raise_error
      lambda { subject.put(204, subject.object_path('nethttp', 'test-sizeless'), sizeless, {"Content-Type" => "text/plain"}) }.should_not raise_error
    end
  end
end
