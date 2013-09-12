require 'spec_helper'

describe "Protocol Buffers", test_client: true do
  before do
    @client = test_client
    @bucket = random_bucket 'protobuf_spec'
  end

  [:BeefcakeProtobuffsBackend].each do |klass|
    bklass = Riak::Client.const_get(klass)
    if bklass.configured?
      describe klass.to_s do
        before do
          @backend = bklass.new(@client, @client.node)
        end

        it_should_behave_like "Unified backend API"

        if "".respond_to?(:encoding) # Ruby 1.9 and later only
          describe "searching fulltext indexes (1.2 and later)", :version => '>= 1.2.0' do
            include_context "search corpus setup"

            it 'should return documents with UTF-8 fields (GH #75)' do
              utf8 = Encoding.find('UTF-8')
              results = @backend.search 'search_test', 'fearless elephant rushed'
              results['docs'].each do |d|
                d.each {|(k,v)| k.encoding.should == utf8; v.encoding.should == utf8 }
              end
            end
          end
        end
      end
    end
  end
end
