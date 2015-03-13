require 'riak/errors/crdt_error'

module Riak::Search

  # A single document from a Riak Search 2 response. Materializes the document
  # fields into {Riak::BucketType}, {Riak::Bucket}, and {Riak::RObject}
  # instances on demand.
  class ResultDocument
    # @return [Riak::Client]
    attr_reader :client

    # @return [Hash] the de-serialized hash returned from Solr
    attr_reader :raw

    # Iniitalize a {ResultDocument} with the client queried and the relevant
    # part of the JSON returned from the search API.
    #
    # This is automatically called by {Riak::Search::ResultCollection}#docs
    #
    # @api private
    def initialize(client, raw)
      @client = client
      @raw = raw
    end

    # @return [String] the key of the result
    def key
      @key ||= raw['_yz_rk']
    end

    # @return [Riak::BucketType] the bucket type containing the result
    def bucket_type
      @bucket_type ||= client.bucket_type raw['_yz_rt']
    end

    # @return [Riak::Bucket] the bucket containing the result
    def bucket
      @bucket ||= bucket_type.bucket raw['_yz_rb']
    end

    # @return [Numeric] the score of the match
    def score
      @score ||= Float(raw['score'])
    end

    def type_class
      bucket_type.data_type_class || Riak::RObject
    end

    def crdt?
      type_class != Riak::RObject
    end

    def crdt
      fail Riak::CrdtError::NotACrdt unless crdt?

      type_class.new bucket, key, bucket_type
    end

    def map
      if type_class != Riak::Crdt::Map
        fail Riak::CrdtError::UnexpectedDataType, Riak::Crdt::Map, type_class
      end

      crdt
    end

    # Provides access to other parts of the result document without
    # materializing them. Useful when querying non-default fields.
    #
    # @return [String,Numeric] other search result document field
    def [](field_name)
      raw[field_name.to_s]
    end

    # Loads the {Riak::RObject} referred to by the result document.
    #
    # @return [Riak::RObject]
    def robject
      @robject ||= bucket.get key
    end
  end
end
