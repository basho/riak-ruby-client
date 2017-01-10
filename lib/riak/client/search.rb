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
  class Client
    # (Riak Search) Performs a search via the Solr interface.
    # @overload search(index, query, options={})
    #   @param [String] index the index to query on
    #   @param [String] query a Lucene query string
    # @overload search(query, options={})
    #   Queries the default index
    #   @param [String] query a Lucene query string
    # @param [Hash] options extra options for the Solr query
    # @option options [String] :df the default field to search in
    # @option options [String] :'q.op' the default operator between terms ("or", "and")
    # @option options [String] :wt ("json") the response type - "json" and "xml" are valid
    # @option options [String] :sort ('none') the field and direction to sort, e.g. "name asc"
    # @option options [Fixnum] :start (0) the offset into the query to start from, e.g. for pagination
    # @option options [Fixnum] :rows (10) the number of results to return
    # @return [Hash] the query result, containing the 'responseHeaders' and 'response' keys
    def search(*args)
      options = args.extract_options!
      index, query = args[-2], args[-1]  # Allows nil index, while keeping it as firstargument
      backend do |b|
        b.search(index, query, options)
      end
    end
    alias :select :search
  end
end
