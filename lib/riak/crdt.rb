# Copyright 2010-present Basho Technologies, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'riak/errors/crdt_error'

%w{ operation base inner_register inner_flag counter inner_counter batch_counter hyper_log_log map inner_map batch_map grow_only_set set inner_set typed_collection }.each do |f|
  require "riak/crdt/#{f}"
end

module Riak
  # Container module for Convergent Replicated Data Type
  # features.
  module Crdt

    # These are the default bucket types for the three top-level data types.
    # Broadly, CRDTs require allow_mult to be enabled, and the `datatype`
    # property to be set to the appropriate atom (`counter`, `map`, `set`,
    # 'hll', or 'gset').
    DEFAULT_BUCKET_TYPES = {
      counter: 'counters',
      map: 'maps',
      set: 'sets',
      hll: 'hlls',
      gset: 'gsets',
    }
  end
end
