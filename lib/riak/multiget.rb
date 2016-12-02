require 'riak/client'
require 'riak/bucket'
require 'riak/multi'

module Riak
  # Coordinates a parallel fetch operation for multiple keys.
  class Multiget < Multi
    # @deprecated use perform
    class << self
      alias_method :get_all, :perform
    end

    private

    def work(bucket, key)
      bucket[key]
    rescue Riak::FailedRequest => e
      raise e unless e.not_found?
      nil
    end
  end
end
