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
  class BaseBucketOrTypeProperties
    attr_reader :client

    # @param [Riak::Client] client
    def initialize(client)
      @client = client
    end

    # Write bucket properties and invalidate the cache in this object.
    def store
      client.backend do |be|
        store_properties(be, cached_props)
      end
      @cached_props = nil
      return true
    end

    # Clobber the cached properties, and reload them from Riak.
    def reload
      @cached_props = nil
      cached_props
      true
    end

    # Take bucket properties from a given {Hash} or {Riak::BucketProperties}
    # object.
    # @param [Hash<String, Object>, Riak::BucketProperties] other
    def merge!(other)
      cached_props.merge! other
    end

    # Convert the cached properties into a hash for merging.
    # @return [Hash<String, Object>] the bucket properties in a {Hash}
    def to_hash
      cached_props
    end

    # Read a bucket property
    # @param [String] property_name
    # @return [Object] the bucket property's value
    def [](property_name)
      cached_props[property_name.to_s]
    end

    # Write a bucket property
    # @param [String] property_name
    # @param [Object] value
    def []=(property_name, value)
      value = unwrap_index(value) if property_name == 'search_index'
      cached_props[property_name.to_s] = value
    end

    def get_properties(backend)
      raise NotImplementedError
    end

    def store_properties(backend)
      @cached_props = nil
      return true
    end

    private
    def cached_props
      @cached_props ||= client.backend do |be|
        get_properties(be)
      end
    end

    def unwrap_index(value)
      return value.name if value.is_a? Riak::Search::Index

      value
    end
  end
end
