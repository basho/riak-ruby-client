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
