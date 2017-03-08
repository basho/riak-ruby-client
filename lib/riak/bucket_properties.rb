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
  # Provides a predictable and useful interface to bucket properties. Allows
  # reading, reloading, and setting new values for bucket properties.
  class BucketProperties < BaseBucketOrTypeProperties
    attr_reader :bucket

    # Create a properties object for a bucket (including bucket-typed buckets).
    # @param [Riak::Bucket, Riak::BucketTyped::Bucket] bucket
    def initialize(bucket)
      super(bucket.client)
      @bucket = bucket
    end

    # Write bucket properties and invalidate the cache in this object.
    def store_properties(backend, props)
      backend.bucket_properties_operator.put @bucket, props
    end

    def get_properties(backend)
      backend.bucket_properties_operator.get @bucket
    end
  end
end
