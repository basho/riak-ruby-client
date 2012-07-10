require 'spec_helper'

describe "Protocol Buffers" do
  before do
    @pbc_port ||= $test_server.pb_port
    @http_port ||= $test_server.http_port
    @client = Riak::Client.new(:http_port => @http_port, :pb_port => @pbc_port, :protocol => "pbc")
  end

  [:BeefcakeProtobuffsBackend].each do |klass|
    bklass = Riak::Client.const_get(klass)
    if bklass.configured?
      describe klass.to_s do
        before do
          @backend = bklass.new(@client, @client.node)
        end

        it_should_behave_like "Unified backend API"

        describe "searching fulltext indexes (1.1 and earlier)", :version => '< 1.2.0' do
          include_context "search corpus setup"

          it 'should find document IDs via MapReduce' do
            # Note that the trailing options Hash is ignored when
            # emulating search with MapReduce
            results = @backend.search 'search_test', 'fearless elephant rushed'
            results.should have_key 'docs'
            results.should have_key 'max_score'
            results.should have_key 'num_found'
            results['docs'].should include({"id" => "munchausen-605"})
          end
        end
      end
    end
  end
end
