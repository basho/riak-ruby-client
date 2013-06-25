module Riak
  class IndexCollection < Array
    attr_reader :continuation
    attr_reader :with_terms
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
