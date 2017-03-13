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

require 'riak'

module Riak
  class BucketOrTypeProperties
    attr_reader :client

    def initialize(client)
      @client = client
    end

    # Clobber the cached properties, and reload them from Riak.
    def reload
      @cached_props = nil
      cached_props
      true
    end

    # Write bucket properties and invalidate the cache in this object.
    def store
      @cached_props = nil
      return true
    end

    # Take bucket properties from a given {Hash} or {Riak::BucketProperties}
    # or {Riak::BucketTypeProperties} object.
    # @param [Hash<String, Object>, Riak::BucketProperties, Riak::BucketTypeProperties] other
    def merge!(other)
      cached_props.merge! other
    end

    # Convert the cached properties into a hash for merging.
    # @return [Hash<String, Object>] the bucket or bucket type
    # properties in a {Hash}
    def to_hash
      cached_props
    end

    # Read a bucket or bucket type property
    # @param [String] property_name
    # @return [Object] the property's value
    def [](property_name)
      cached_props[property_name.to_s]
    end

    # Write a bucket or bucket type property
    # @param [String] property_name
    # @param [Object] value
    def []=(property_name, value)
      value = unwrap_index(value) if property_name == 'search_index'
      cached_props[property_name.to_s] = value
    end

    private
    def unwrap_index(value)
      return value.name if value.is_a? Riak::Search::Index
      value
    end
  end
end
