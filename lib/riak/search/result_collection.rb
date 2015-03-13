require 'riak/search'

module Riak::Search

  # A collection of Riak Search 2 ("Yokozuna") results. Provides direct access
  # to the {Riak::RObject} instances found, and access through the #docs method
  # to the results as returned by Solr.
  class ResultCollection
    # @return [Riak::Client]
    attr_reader :client

    # @return [Hash] the de-serialzed hash returned from Solr
    attr_reader :raw

    # @return [Numeric] the maximum score found by Solr
    attr_reader :max_score

    # @return [Integer] the number of documents in this collection
    attr_reader :length

    # @return [Integer] the total number of documents matched, including ones
    #   not returned due to row-limiting
    attr_reader :num_found

    # Initialize a {ResultCollection} with the client queried and the raw
    # JSON returned from the search API.
    #
    # This is automatically called by {Riak::Search::Query}#results
    #
    # @api private
    def initialize(client, raw_results)
      @client = client
      @raw = raw_results
      @max_score = raw['max_score']
      @num_found = raw['num_found']
      @length = raw['docs'].length
    end

    # Access the individual documents from the search results. The document
    # metadata are each wrapped in a {Riak::Search::ResultDocument}.
    #
    # @return [Array<Riak::Search::ResultDocument>] individual documents
    def docs
      @docs ||= raw['docs'].map do |result|
        ResultDocument.new client, result
      end
    end

    # @return [Boolean] does this collection contain any documents?
    def empty?
      length == 0
    end

    # @param [Integer] index the index of the [Riak::RObject] to load and return
    # @return [Riak::RObject,NilClass] the found object, or nil if the index
    #   is out of range
    def [](index)
      doc = docs[index]
      return nil if doc.nil?

      doc.object
    end

    # @return [Riak::RObject,NilClass] the first found object, or nil if the
    #   index is out of range
    def first
      self[0]
    end

    def crdts
      docs.select(&:crdt?).map(&:crdt)
    end

    # {Enumerable}-compatible iterator method. If a block is given, yields with
    # each {Riak::RObject} in the collection. If no block is given, returns an
    # {Enumerator} over each {Riak::RObject in the collection.
    # @yieldparam robject [Riak::RObject]
    # @return [Enumerator<Riak::RObject>]
    def each_robject
      enum = docs.each_with_index

      if block_given?
        enum.each do |doc, idx|
          yield self[idx]
        end
      else
        Enumerator.new do |yielder|
          enum.each do |doc, idx|
            yielder << self[idx]
          end
        end
      end
    end
  end
end
