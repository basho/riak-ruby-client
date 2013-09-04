shared_context "search corpus setup" do
  before do
    @bucket = @client.bucket('search_test')
    @bucket.enable_index!
    idx = 0
    IO.foreach("spec/fixtures/munchausen.txt") do |para|
      next if para =~ /^\s*$|introduction|chapter/i
      idx += 1
      Riak::RObject.new(@bucket, "munchausen-#{idx}") do |obj|
        obj.content_type = 'text/plain'
        obj.raw_data = para
        @backend.store_object(obj)
      end
    end
  end
end
