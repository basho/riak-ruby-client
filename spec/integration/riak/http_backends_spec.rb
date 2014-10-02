require 'spec_helper'

describe "HTTP" do
  before do
    @web_port = test_server.http_port
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

        describe "searching fulltext indexes (1.1 and earlier)", :version => "< 1.2.0" do
          include_context "search corpus setup"

          it 'should find indexed documents, returning ids' do
            results = @backend.search 'search_test', 'fearless elephant rushed', :fl => 'id'
            results.should have_key 'docs'
            results.should have_key 'max_score'
            results.should have_key 'num_found'
            results['docs'].should include({"id" => "munchausen-605"})
          end

          it 'should find indexed documents, returning documents' do
            # For now use '*' until #122 is merged into riak_search
            results = @backend.search 'search_test', 'fearless elephant rushed', :fl => '*'
            results.should have_key 'docs'
            results.should have_key 'max_score'
            results.should have_key 'num_found'
            results['docs'].should include({"id" => "munchausen-605", "value" => "Fearless I advanced against the elephant, desirous to take alive the haughty Tippoo Sahib; but he drew a pistol from his belt, and discharged it full in my face as I rushed upon him, which did me no further harm than wound my cheek-bone, which disfigures me somewhat under my left eye. I could not withstand the rage and impulse of that moment, and with one blow of my sword separated his head from his body.\n"})
          end
        end

        context "clearing bucket properties" do
          it "should return false when unsupported", :version => "< 1.3.0" do
            @backend.clear_bucket_props('foo').should be_false
          end

          it "should reset a previously set property to the default", :version => ">= 1.3.0" do
            bucket = @client['bucketpropscleartest']
            original_n = @backend.get_bucket_props(bucket)['n_val']
            @backend.set_bucket_props(bucket, {'n_val' => 2})
            @backend.get_bucket_props(bucket)['n_val'].should == 2
            @backend.clear_bucket_props(bucket)
            @backend.get_bucket_props(bucket)['n_val'].should == original_n
          end
        end

        context "using Luwak", :version => "< 1.1.0" do
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

        describe 'key and bucket escaping' do
          let(:default_bucket){ @client[rand(36**10).to_s(36)] }

          { 'question mark' => 'question?marks',
            'hash' => 'hashtag#riak',
            'slash' => 'slash/fiction',
            'space' => 'space opera',
            'plus' => 'plus+one'
          }.each do |k, v|
            it "doesn't mangle keys with a #{k} in them" do
              obj = default_bucket.new v
              obj.content_type = 'text/plain'
              obj.data = rand(36**10).to_s(36)
              obj.store
              
              o2 = nil
              expect{ o2 = default_bucket.get v }.to_not raise_error
              expect(o2.data).to eq obj.data
            end
            
            it "doesn't mangle buckets with a #{k} in them" do
              bucket = @client[v]
              obj = bucket.new rand(36**10).to_s(36)
              obj.content_type = 'text/plain'
              obj.data = rand(36**10).to_s(36)
              obj.store

              o2 = nil
              expect{ o2 = bucket.get obj.key }.to_not raise_error
              expect(o2.data).to eq obj.data
            end
          end
        end
      end
    end
  end

  class SizelessReader < Array
    def read(*args)
      shift
    end

    undef :size
  end

  describe 'NetHTTPBackend' do
    subject { Riak::Client::NetHTTPBackend.new(@client, @client.node) }
    shared_examples "IO uploads" do |io|
      it "should upload without error" do
        lambda do
          Timeout::timeout(2) do
            subject.put(
                        204,
                        subject.object_path('nethttp', 'test-io'),
                        io,
                        {'Content-Type' => 'text/plain'}
                        )
          end
        end.should_not raise_error
      end
    end
    
    context "File" do
      include_examples "IO uploads", File.open(__FILE__)
    end
    context "Sized reader" do
      include_examples "IO uploads", StringIO.new(%w{foo bar baz}.join)
    end
    context "Sizeless reader" do
      include_examples "IO uploads", SizelessReader.new(%w{foo bar baz})
    end
  end
end
