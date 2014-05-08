# encoding: utf-8
shared_context "search corpus setup" do
  before do
    @search_bucket = random_bucket 'search_test'
    @backend.create_search_index @search_bucket.name

    wait_until{ !@backend.get_search_index(@search_bucket.name).nil? }

    @client.set_bucket_props(@search_bucket,
                             {search_index: @search_bucket.name},
                             'yokozuna')

    wait_until do
      p = @client.get_bucket_props(@search_bucket)
      p['search_index'] == @search_bucket.name
    end

    idx = 0
    old_encoding = Encoding.default_external
    Encoding.default_external = Encoding::UTF_8
    IO.foreach("spec/fixtures/munchausen.txt") do |para|
      next if para =~ /^\s*$|introduction|chapter/ui
      idx += 1
      Riak::RObject.new(@search_bucket, "munchausen-#{idx}") do |obj|
        obj.content_type = 'text/plain'
        obj.raw_data = para
        @backend.store_object(obj, type: 'yokozuna')
      end
    end
    Encoding.default_external = old_encoding
    
    wait_until do
      results = @backend.search(@search_bucket.name, 
                                'I bade the lovely creature dry her eyes',
                                df: 'text')
      results['docs'].length > 0
    end
  end
end
