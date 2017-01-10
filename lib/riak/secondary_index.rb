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

require 'riak/index_collection'
require 'riak/bucket_typed/bucket'

module Riak
  # {Riak::SecondaryIndex} provides an object-oriented interface to secondary
  # index ("2i") functionality in Riak, available on the `memory` and `leveldb`
  # backends.
  class SecondaryIndex
    include Util::Translation
    include Client::FeatureDetection

    # Create a Riak Secondary Index operation
    # @param [Bucket] bucket the {Riak::Bucket} we'll query against
    # @param [String] index the index name
    # @param [String,Integer,Range<String,Integer>] query
    #   a single value or range of values to query for
    def initialize(bucket, index, query, options = {})
      @bucket = bucket
      @client = @bucket.client
      @index = index
      @query = query
      @options = options

      if @bucket.is_a? Riak::BucketTyped::Bucket
        @options = { type: @bucket.type.name }.merge @options
      end

      validate_options
    end

    def get_server_version
      @client.backend { |b| b.send :get_server_version }
    end

    # Get the array of matched keys
    def keys(&block)
      @collection ||=
        @client.backend do |b|
          b.get_index @bucket, @index, @query, @options, &block
        end
    end

    # Get the array of values
    def values
      @values ||= @bucket.get_many(keys).values
    end

    # Get a new SecondaryIndex fetch for the next page
    def next_page
      fail t('index.no_next_page') unless keys.continuation

      self.class.new(@bucket,
                     @index,
                     @query,
                     @options.merge(continuation: keys.continuation))
    end

    # Determine whether a SecondaryIndex fetch has a next page available
    def has_next_page?
      !!keys.continuation
    end

    private

    def validate_options
      if paginated? && !index_pagination?
        fail t('index.pagination_not_available')
      end

      if @options[:return_terms] && !index_return_terms?
        fail t('index.return_terms_not_available')
      end

      fail t('index.include_terms_is_wrong') if @options[:include_terms]
    end

    def paginated?
      @options[:continuation] || @options[:max_results]
    end
  end
end
