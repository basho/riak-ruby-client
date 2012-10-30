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
      # @param [Array] data the phase result
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
