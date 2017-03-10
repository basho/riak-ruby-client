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

require 'riak/client/beefcake/bucket_or_type_properties_operator'
require 'riak/client/beefcake/encoding_methods'

class Riak::Client::BeefcakeProtobuffsBackend
  def bucket_properties_operator
    BucketPropertiesOperator.new(self)
  end

  class BucketPropertiesOperator < BucketOrTypePropertiesOperator
    include EncodingMethods

    def get_properties(bucket, options = {})
      return backend.protocol do |p|
        p.write :GetBucketReq, get_request(bucket, options)
        p.expect :GetBucketResp, RpbGetBucketResp
      end
    end

    def put_properties(bucket, properties = {}, options = {})
      request = put_request bucket, properties, options
      backend.protocol do |p|
        p.write :SetBucketReq, request
        p.expect :SetBucketResp
      end
    end

    def reset(bucket, options)
      req_options = options.merge name_options(bucket)
      req = RpbResetBucketReq.new req_options
      backend.protocol do |p|
        p.write :ResetBucketReq, req
        p.expect :ResetBucketResp
      end
    end

    private
    def get_request(bucket, options)
      RpbGetBucketReq.new options.merge name_options(bucket)
    end

    def put_request(bucket, props, options)
      req_options = options.merge name_options(bucket)
      req_options[:props] = RpbBucketProps.new props.symbolize_keys

      RpbSetBucketReq.new req_options
    end

    def name_options(bucket)
      o = {}
      if bucket.is_a? Riak::Bucket
        o[:bucket] = maybe_encode(bucket.name)
        o[:type] = maybe_encode(bucket.type.name) if bucket.needs_type?
      else
        o[:bucket] = maybe_encode(bucket)
      end

      return o
    end
  end
end
