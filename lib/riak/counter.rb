module Riak
  class Counter
    include Util::Translation
    attr_accessor :bucket
    attr_accessor :key

    def initialize(bucket, key)
      @bucket, @key = bucket, key

      validate_bucket
    end

    def increment(amount=1)
      validate_amount amount
    end

    def decrement(amount=1)
      increment(-amount)
    end

    private
    def validate_bucket
      raise ArgumentError, t("counter.bucket_needs_allow_mult") unless bucket.allow_mult
    end

    def validate_amount(amount)
      raise ArgumentError, t("counter.increment_by_integer") unless amount.is_a? Integer
    end
  end
end
