shared_context "search corpus setup" do
  before do
    @search_bucket = random_bucket 'search_test'
    @backend.create_search_index @search_bucket.name
    @search_bucket.props = {search_index: @search_bucket.name}
    idx = 0
    IO.foreach("spec/fixtures/munchausen.txt") do |para|
      next if para =~ /^\s*$|introduction|chapter/i
      idx += 1
      Riak::RObject.new(@search_bucket, "munchausen-#{idx}") do |obj|
        obj.content_type = 'text/plain'
        obj.raw_data = para
        @backend.store_object(obj)
      end
    end

    sleep 1
  end
end
