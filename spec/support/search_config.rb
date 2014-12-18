module SearchConfig
  include TestClient

  def search_bucket
    return @search_bucket if defined? @search_bucket
    type = test_client.bucket_type 'yokozuna'
    @search_bucket = type.bucket "search_config-#{random_key}"
  end

  def index_name
    @index_name ||= search_bucket.name
  end

  def create_index
    return if defined? @index_exists

    test_client.create_search_index index_name

    wait_until do
      test_client.get_search_index index_name
    end

    @index_exists = true
  end

  def configure_bucket
    return if defined? @bucket_configured

    create_index

    test_client.set_bucket_props(search_bucket, 
                                 { search_index: index_name },
                                 'yokozuna')

    wait_until do
      props = test_client.get_bucket_props search_bucket, type: 'yokozuna'
      props['search_index'] == index_name
    end

    @bucket_configred = true
  end

  def load_corpus
    return if defined? @corpus_loaded

    configure_bucket

    old_encoding = Encoding.default_external
    Encoding.default_external = Encoding::UTF_8

    IO.foreach('spec/fixtures/bitcask.txt').with_index do |para, idx|
      next if para =~ /^\s*$|introduction|chapter/ui

      Riak::RObject.new(search_bucket, "bitcask-#{idx}") do |obj|
        obj.content_type = 'text/plain'
        obj.raw_data = para
        obj.store
      end
    end

    Encoding.default_external = old_encoding

    wait_until do
      results = @client.search(index_name,
                               'contain your entire keyspace',
                               df: 'text')

      results['docs'].length > 0
    end

    @corpus_loaded = true
  end
end

RSpec.configure do |config|
  config.include SearchConfig, search_config: true
end
