require 'riak/errors/failed_request'

module Riak

  # A distributed counter that supports incrementing by positive and negative
  # integers.
  class Counter
    include Util::Translation
    attr_accessor :bucket
    attr_accessor :key
    attr_accessor :client

    # Create a Riak counter.
    # @param [Bucket] bucket the {Riak::Bucket} for this counter
    # @param [String] key the name of the counter
    def initialize(bucket, key)
      raise ArgumentError, t("bucket_type", bucket: bucket.inspect) unless bucket.is_a? Bucket
      raise ArgumentError, t("string_type", string: key.inspect) unless key.is_a? String
      @bucket, @key = bucket, key
      @client = bucket.client

      validate_bucket
    end

    # Retrieve the current value of the counter.
    # @param [Hash] options
    # @option options [Fixnum,String] :r ("quorum") read quorum (numeric or
    # symbolic)
    def value(options = {})
      backend do |backend|
        backend.get_counter bucket, key, options
      end
    end
    alias :to_i :value

    # Increment the counter and return its new value.
    # @param amount [Integer] the amount to increment the counter by.
    def increment_and_return(amount = 1)
      increment amount, return_value: true
    end

    # Decrement the counter and return its new value.
    # @param amount [Integer] the amount to decrement the counter by. Negative
    # values increment the counter.
    def decrement_and_return(amount = 1)
      increment_and_return -amount
    end

    # Increment the counter.
    # @param amount [Integer] the amount to increment the counter by
    # @param [Hash] options
    # @option options [Boolean] :return_value whether to return the new counter
    # value. Default false.
    # @option options [Fixnum,String] :r ("quorum") read quorum (numeric or
    # symbolic)
    # @option options [Fixnum] :w the "w" parameter (Write quorum)
    # @option options [Fixnum] :dw the "dw" parameter (Durable-write quorum)
    def increment(amount = 1, options = {})
      validate_amount amount

      backend do |backend|
        backend.post_counter bucket, key, amount, options
      end
    end

    # Decrement the counter.
    # @param amount [Integer] the amount to decrement the counter by. Negative
    # values increment the counter.
    # @param [Hash] options
    # @option options [Boolean] :return_value whether to return the new counter
    # value. Default false.
    # @option options [Fixnum,String] :r ("quorum") read quorum (numeric or
    # symbolic)
    # @option options [Fixnum] :w the "w" parameter (Write quorum)
    # @option options [Fixnum] :dw the "dw" parameter (Durable-write quorum)
    def decrement(amount = 1, options = {})
      increment(-amount, options)
    end

    private
    def validate_bucket
      raise ArgumentError, t("counter.bucket_needs_allow_mult") unless bucket.allow_mult
    end

    def validate_amount(amount)
      raise ArgumentError, t("counter.increment_by_integer") unless amount.is_a? Integer
    end

    def backend(&blk)
      begin
        return client.backend &blk
      rescue Riak::FailedRequest => e
        raise QuorumError.new e if e.message =~ /unsatisfied/
        raise e
      end
    end

    class QuorumError < Riak::FailedRequest
    end
  end
end
