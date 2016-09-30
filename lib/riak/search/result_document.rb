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

    # Determining if the object is a CRDT or regular K-V object requires
    # figuring out what data type the bucket type contains. If the bucket type
    # has no data type, treat it as a regular K-V object.
    #
    # @return [Class] the class of the object referred to by the search result
    def type_class
      bucket_type.data_type_class || Riak::RObject
    end

    # @return [Boolean] if the object is a CRDT
    def crdt?
      type_class != Riak::RObject
    end

    # @raise [Riak::CrdtError::NotACrdt] if the result is not a CRDT
    # @return [Riak::Crdt::Base] the materialized CRDT
    def crdt
      fail Riak::CrdtError::NotACrdt unless crdt?

      type_class.new bucket, key, bucket_type
    end

    # If the result document describes a counter, return it.
    #
    # @return [Riak::Crdt::Counter]
    # @raise [Riak::CrdtError::NotACrdt] if the result is not a CRDT
    # @raise [Riak::CrdtError::UnexpectedDataType] if the CRDT is not a counter
    def counter
      return crdt if check_type_class Riak::Crdt::Counter
    end

    # If the result document describes a map, return it.
    #
    # @return [Riak::Crdt::Map]
    # @raise [Riak::CrdtError::NotACrdt] if the result is not a CRDT
    # @raise [Riak::CrdtError::UnexpectedDataType] if the CRDT is not a map
    def map
      return crdt if check_type_class Riak::Crdt::Map
    end

    # If the result document describes a set, return it.
    #
    # @return [Riak::Crdt::Set]
    # @raise [Riak::CrdtError::NotACrdt] if the result is not a CRDT
    # @raise [Riak::CrdtError::UnexpectedDataType] if the CRDT is not a set
    def set
      return crdt if check_type_class Riak::Crdt::Set
    end

    # If the result document describes a set, return it.
    #
    # @return [Riak::Crdt::HyperLogLog]
    # @raise [Riak::CrdtError::NotACrdt] if the result is not a CRDT
    # @raise [Riak::CrdtError::UnexpectedDataType] if the CRDT is not a hyper_log_log
    def hyper_log_log
      return crdt if check_type_class Riak::Crdt::HyperLogLog
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
      if crdt?
        fail Riak::SearchError::UnexpectedResultError.
              new(Riak::RObject, type_class)
      end

      @robject ||= bucket.get key
    end

    # Returns an appropriate object, be it CRDT or K-V.
    def object
      return crdt if crdt?
      robject
    end

    private

    def check_type_class(klass)
      return true if type_class == klass
      fail Riak::CrdtError::NotACrdt if type_class == Riak::RObject
      fail Riak::CrdtError::UnexpectedDataType.new(klass, type_class)
    end
  end
end
