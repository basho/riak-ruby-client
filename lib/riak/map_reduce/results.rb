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
  class MapReduce
    # @api private
    # Collects and normalizes results from MapReduce requests
    class Results
      # Creates a new result collector
      # @param [MapReduce] mr the MapReduce query
      def initialize(mr)
        @keep_count = mr.query.select {|p| p.keep }.size
        @hash = create_results_hash(mr.query)
      end

      # Adds a new result to the collector
      # @param [Fixnum] phase the phase index
      # @param [Array] result the phase result
      def add(phase, result)
        @hash[phase] += result
      end

      # Coalesces the query results
      # @return [Array] the query results, coalesced according to the
      #   phase configuration
      def report
        if @keep_count > 1
          @hash.to_a.sort.map {|(num, results)| results }
        else
          @hash[@hash.keys.first]
        end
      end

      private
      def create_results_hash(query)
        # When the query is empty, only bucket/key pairs are returned,
        # but implicitly in phase 0.
        return { 0 => [] } if query.empty?

        # Pre-populate the hash with empty results for kept phases.
        # Additionally, the last phase is always implictly kept, even
        # when keep is false.
        query.inject({}) do |hash, phase|
          if phase.keep || query[-1] == phase
            hash[query.index(phase)] = []
          end
          hash
        end
      end
    end
  end
end
