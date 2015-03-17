module CrdtSearchConfig
  include SearchConfig

  def query_text
    'arroz_register:frijoles OR set:frijoles OR counter:83475'
  end

  def counter_bucket
    @counter_bucket ||= bucket_for :counter
  end

  def map_bucket
    @map_bucket ||= bucket_for :map
  end

  def set_bucket
    @set_bucket ||= bucket_for :set
  end

  def first_counter
    return @first_counter if defined? @first_counter

    @first_counter = Riak::Crdt::Counter.new counter_bucket, nil
    @first_counter.increment 83475 # BEANS in leet, i guess

    @first_counter.tap do |c|
      wait_until do
        index.query('counter:83475').results.length > 0
      end
    end
  end

  def first_map
    return @first_map if defined? @first_map

    @first_map = Riak::Crdt::Map.new map_bucket, nil
    @first_map.registers['arroz'] = 'frijoles'

    @first_map.tap do |m|
      wait_until do
        index.query('arroz_register:frijoles').results.length > 0
      end
    end
  end

  def first_set
    return @first_set if defined? @first_set

    @first_set = Riak::Crdt::Set.new set_bucket, nil
    @first_set.add 'frijoles'

    @first_set.tap do |s|
      wait_until do
        index.query('set:frijoles').results.length > 0
      end
    end
  end

  def configure_crdt_buckets
    return if defined? @crdt_buckets_configured

    create_index

    cp = Riak::BucketProperties.new counter_bucket
    mp = Riak::BucketProperties.new map_bucket
    sp = Riak::BucketProperties.new set_bucket

    cp['search_index'] = index_name
    cp.store
    mp['search_index'] = index_name
    mp.store
    sp['search_index'] = index_name
    sp.store

    wait_until do
      cp.reload
      cp['search_index'] == index_name
    end
    wait_until do
      mp.reload
      mp['search_index'] == index_name
    end
    wait_until do
      sp.reload
      sp['search_index'] == index_name
    end

    @crdt_buckets_configured = true
  end

  private

  def bucket_for(type)
    @bucket_for ||= Hash.new
    return @bucket_for[type] if @bucket_for[type]

    test_client.
      bucket_type(Riak::Crdt::DEFAULT_BUCKET_TYPES[type]).
      bucket("crdt-search-#{ type }-#{ random_key }").
      tap do |bucket|
      @bucket_for[type] = bucket
      props = Riak::BucketProperties.new bucket
      props['search_index'] = index.name
      props.store

      wait_until do
        props.reload
        props['search_index'] == index.name
      end
    end
  end
end

RSpec.configure do |config|
  config.include CrdtSearchConfig, crdt_search_config: true
end
