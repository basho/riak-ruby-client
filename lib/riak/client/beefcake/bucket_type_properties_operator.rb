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
  def bucket_type_properties_operator
    BucketTypePropertiesOperator.new(self)
  end

  class BucketTypePropertiesOperator < BucketOrTypePropertiesOperator
    include EncodingMethods

    def get_properties(bucket_type, options = {})
      return backend.protocol do |p|
        p.write :GetBucketTypeReq, get_request(bucket_type, options)
        p.expect :GetBucketResp, RpbGetBucketResp
      end
    end

    def put_properties(bucket_type, properties = {}, options = {})
      request = put_request bucket_type, properties, options
      backend.protocol do |p|
        p.write :SetBucketTypeReq, request
        p.expect :SetBucketResp
      end
    end

    private
    def get_request(bucket_type, options)
      RpbGetBucketTypeReq.new options.merge name_options(bucket_type)
    end

    def put_request(bucket_type, props, options)
      req_options = options.merge name_options(bucket_type)
      req_options[:props] = RpbBucketProps.new props.symbolize_keys

      RpbSetBucketTypeReq.new req_options
    end

    def name_options(bucket_type)
      o = {}
      o[:type] = if bucket_type.is_a? Riak::BucketType
                   maybe_encode(bucket_type.name)
                 else
                   maybe_encode(bucket_type)
                 end
      return o
    end
  end
end
