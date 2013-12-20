%w{ operation base register flag counter inner_counter batch_counter map inner_map batch_map set inner_set typed_collection }.each do |f|
  require "riak/crdt/#{f}"
end

module Riak
  # Container module for Convergent Replicated Data Type
  # features.
  module Crdt
    DEFAULT_BUCKET_TYPES = {
      counter: 'counters',
      map: 'maps',
      set: 'sets',
    }
  end
end
