module Riak
  class Counter
    include Util::Translation
    attr_accessor :bucket
    attr_accessor :key
    attr_accessor :client

    def initialize(bucket, key)
      @bucket, @key = bucket, key
      @client = bucket.client

      validate_bucket
    end

    def value(options={})
      client.backend do |backend|
        backend.get_counter bucket, key, options
      end
    end
    alias :to_i :value

    def increment_and_return(amount=1)
      increment amount, return_value: true
    end

    def increment(amount=1, options={})
      validate_amount amount

      client.backend do |backend|
        backend.post_counter bucket, key, amount, options
      end
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
