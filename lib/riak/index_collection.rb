module Riak

  # IndexCollection provides extra tools for managing index matches returned by
  # a Secondary Index query. In Riak 1.4, these queries can be paginaged, and
  # match keys up with the index values they matched against.
  class IndexCollection < Array

    # @return [String] The continuation used to retrieve the next page of a
    # paginated query.
    attr_accessor :continuation

    # @return [Hash<Integer/String, String>] A hash of index keys (String or
    # Integer, depending on whether the query was a binary or integer) to
    # arrays of keys.
    attr_accessor :with_terms

    def self.new_from_json(json)
      parsed = JSON.parse json
      fresh = nil
      if parsed['keys']
        fresh = new parsed['keys'] 
      elsif parsed['results']
        fresh_terms = load_json_terms(parsed)
        fresh = new fresh_terms.values.flatten
        fresh.with_terms = fresh_terms
      else
        fresh = new []
      end
      fresh.continuation = parsed['continuation']

      fresh
    end

    def self.new_from_protobuf(message)
      fresh = nil
      if message.keys
        fresh = new message.keys
      elsif message.results
        fresh_terms = load_pb_terms(message)
        fresh = new fresh_terms.values.flatten
        fresh.with_terms = fresh_terms
      else
        fresh = new
      end
      fresh.continuation = message.continuation

      fresh
    end

    private
    def self.load_json_terms(parsed)
      fresh_terms = Hash.new{Array.new}
      parsed['results'].each do |r|
        k = r.keys.first
        v = r[k]
        fresh_terms[k] += [v]
      end

      fresh_terms
    end

    def self.load_pb_terms(message)
      fresh_terms = Hash.new{Array.new}
      message.results.each do |r|
        fresh_terms[r.key] += [r.value]
      end

      fresh_terms
    end
  end
end
