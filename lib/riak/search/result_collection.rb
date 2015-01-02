require 'riak/search'
require 'ostruct'

module Riak::Search
  class ResultCollection
    attr_reader :client
    attr_reader :raw
    attr_reader :max_score
    attr_reader :length
    attr_reader :num_found

    def initialize(client, raw_results)
      @client = client
      @raw = raw_results
      @max_score = raw['max_score']
      @num_found = raw['num_found']
      @length = raw['docs'].length
    end

    def docs
      @docs ||= raw['docs'].map do |result|
        ResultDocument.new client, result
      end
    end

    def empty?
      length == 0
    end

    def [](index)
      doc = docs[index]
      return nil if doc.nil?

      doc.robject
    end

    def first
      self[0]
    end

    def each
      enum = docs.each_with_index

      if block_given?
        enum.each do |doc, idx|
          yield self[idx]
        end
      else
        return enum
      end
    end
  end
end
