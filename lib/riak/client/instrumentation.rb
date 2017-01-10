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

class Riak::Client
  include Instrumentable

  client_payload = {client_id: :client_id}

  instrument_method :buckets, 'riak.list_buckets', client_payload
  instrument_method :list_buckets, 'riak.list_buckets', client_payload
  instrument_method :list_keys, 'riak.list_keys', client_payload
  instrument_method :set_bucket_props, 'riak.set_bucket_props', client_payload
  instrument_method :get_bucket_props, 'riak.get_bucket_props', client_payload
  instrument_method :clear_bucket_props, 'riak.clear_bucket_props', client_payload
  instrument_method :get_index, 'riak.get_index', client_payload
  instrument_method :store_object, 'riak.store_object', client_payload
  instrument_method :get_object, 'riak.get_object', client_payload
  instrument_method :reload_object, 'riak.reload_object', client_payload
  instrument_method :delete_object, 'riak.delete_object', client_payload
  instrument_method :mapred, 'riak.map_reduce', client_payload
  instrument_method :ping, 'riak.ping', client_payload
end
