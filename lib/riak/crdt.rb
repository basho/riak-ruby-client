%w{base counter map set}.each do |f|
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
