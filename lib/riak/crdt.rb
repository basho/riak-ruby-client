require 'riak/errors/crdt_error'

%w{ operation base inner_register inner_flag counter inner_counter batch_counter map inner_map batch_map set inner_set typed_collection }.each do |f|
  require "riak/crdt/#{f}"
end

module Riak
  # Container module for Convergent Replicated Data Type
  # features.
  module Crdt

    # These are the default bucket types for the three top-level data types.
    # Broadly, CRDTs require allow_mult to be enabled, and the `datatype`
    # property to be set to the appropriate atom (`counter`, `map`, or `set`).
    DEFAULT_BUCKET_TYPES = {
      counter: 'counters',
      map: 'maps',
      set: 'sets',
    }
  end
end
