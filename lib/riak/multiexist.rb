require 'riak/client'
require 'riak/bucket'
require 'riak/multi'

module Riak
  # Coordinates a parallel exist? operation for multiple keys.
  class Multiexist < Multi
    private

    def work(bucket, key)
      bucket.exists?(key)
    end
  end
end
