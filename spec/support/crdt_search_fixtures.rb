module CrdtSearchFixtures
  def map_result_score
    43.21
  end

  def maps_type_name
    'maps'
  end

  def maps_bucket_type
    return @maps_bucket_type if defined? @maps_bucket_type

    @maps_bucket_type = instance_double('Riak::BucketType').tap do |bt|
      allow(bt).to receive(:bucket).
                    with(bucket_name).
                    and_return(map_bucket)
      allow(bt).to receive(:data_type_class).
                    and_return(Riak::Crdt::Map)
    end
  end

  def map_bucket
    @map_bucket ||= instance_double('Riak::BucketTyped::Bucket')
  end

  def map_raw
    @map_raw ||= {
      'score'=>map_result_score,
      '_yz_rb'=>bucket_name,
      '_yz_rt'=>maps_type_name,
      '_yz_rk'=>'map-key'
    }
  end

  def map_results
    @map_results ||= Riak::Search::ResultDocument.new client, map_raw
  end
end

RSpec.configure do |config|
  config.include CrdtSearchFixtures, crdt_search_fixtures: true
end
