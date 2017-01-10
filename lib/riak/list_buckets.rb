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

module Riak
  class ListBuckets
    def initialize(client, options, block)
      @client = client
      @block = block
      @options = options
      perform_request
    end

    def perform_request
      @client.backend do |be|
        be.list_buckets @options, &wrapped_block
      end
    end

    private

    def wrapped_block
      proc do |bucket_names|
        next if bucket_names.nil?
        bucket_names.each do |bucket_name|
          bucket = @client.bucket bucket_name
          @block.call bucket
        end
      end
    end
  end
end
