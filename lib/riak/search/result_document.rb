module Riak::Search
  class ResultDocument
    attr_reader :client
    attr_reader :raw

    def initialize(client, raw)
      @client = client
      @raw = raw
    end

    def key
      @key ||= raw['_yz_rk']
    end

    def bucket_type
      @bucket_type ||= client.bucket_type raw['_yz_rt']
    end

    def bucket
      @bucket ||= bucket_type.bucket raw['_yz_rb']
    end

    def score
      @score ||= Float(raw['score'])
    end

    def [](field_name)
      raw[field_name.to_s]
    end

    def robject
      @robject ||= bucket.get key
    end
  end
end
