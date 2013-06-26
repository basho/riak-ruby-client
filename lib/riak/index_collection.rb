module Riak

  # IndexCollection provides extra tools for managing index matches returned by
  # a Secondary Index query. In Riak 1.4, these queries can be paginaged, and
  # match keys up with the index values they matched against.
  class IndexCollection < Array

    # @return [String] The continuation used to retrieve the next page of a
    # paginated query.
    attr_reader :continuation

    # @return [Hash<Integer/String, String>] A hash of index keys (String or
    # Integer, depending on whether the query was a binary or integer) to
    # arrays of keys.
    attr_reader :with_terms

    # Create an IndexCollection from a JSON string.
    def initialize(json)
      parsed = JSON.parse json
      if parsed['keys']
        super parsed['keys'] 
      else
        load_terms(parsed)
        super @with_terms.values.flatten
      end
      @continuation = parsed['continuation']
    end

    private
    def load_terms(parsed)
      @with_terms = Hash.new{Array.new}
      parsed['results'].each do |r|
        k = r.keys.first
        v = r[k]
        @with_terms[k] += [v]
      end
    end
  end
end
