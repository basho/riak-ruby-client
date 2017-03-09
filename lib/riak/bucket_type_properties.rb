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
require 'riak/base_bucket_or_type_properties'

module Riak
  # Provides a predictable and useful interface to bucket type properties. Allows
  # reading, reloading, and setting new values for bucket type properties.
  class BucketTypeProperties < BaseBucketOrTypeProperties
    attr_reader :bucket_type

    # Create a properties object for a bucket type
    # @param [Riak::BucketType] bucket_type
    def initialize(bucket_type)
      super(bucket_type.client)
      @bucket_type = bucket_type
    end

    # Write bucket type properties and invalidate the cache in this object.
    def store_properties(backend, props)
      backend.bucket_type_properties_operator.put @bucket_type, props
    end

    def get_properties(backend)
      backend.bucket_type_properties_operator.get @bucket_type
    end
  end
end
