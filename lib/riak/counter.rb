module Riak
  class Counter
    include Util::Translation
    attr_accessor :bucket
    attr_accessor :key

    def initialize(bucket, key)
      @bucket, @key = bucket, key

      validate_bucket
    end

    private
    def validate_bucket
      raise ArgumentError, t("counter.bucket_needs_allow_mult") unless bucket.allow_mult
    end
  end
end
