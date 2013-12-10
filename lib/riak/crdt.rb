%w{ operation base register flag counter inner_counter map inner_map batch_map set inner_set typed_collection }.each do |f|
  require "riak/crdt/#{f}"
end

module Riak
  # Container module for Convergent Replicated Data Type
  # features.
  module Crdt
    DEFAULT_SET_BUCKET_TYPE = 'sets'
    DEFAULT_MAP_BUCKET_TYPE = 'maps'
    DEFAULT_COUNTER_BUCKET_TYPE = 'counters'
  end
end
