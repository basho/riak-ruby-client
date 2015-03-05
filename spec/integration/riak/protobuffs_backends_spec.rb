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

        describe "searching yokozuna" do
          include_context "search corpus setup"

          it 'returns documents with UTF-8 fields (GH #75)' do
            utf8 = Encoding.find('UTF-8')
            results = @backend.search(
              @search_bucket.name,
              'fearless elephant rushed',
              df: 'text'
            )
            results['docs'].each do |d|
              d.each do |(k, v)|
                expect(k.encoding).to eq(utf8)
                expect(v.encoding).to eq(utf8)
              end
            end
          end
        end
      end
    end
  end
end
