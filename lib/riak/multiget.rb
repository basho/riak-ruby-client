require 'riak/client'
require 'riak/bucket'
require 'riak/cluster'

module Riak
  # Coordinates a parallel fetch operation for multiple values.
  class Multiget
    include Util::Translation

    # @return [Riak::Client] the associated client
    attr_reader :client

    # @return [Array<Bucket, String>] fetch_list an {Array} of {Bucket} and {String} keys to fetch
    attr_reader :fetch_list

    # @return [Hash<fetch_list_entry, RObject] result_hash a {Hash} of {Bucket} and {String} key pairs to {RObject} instances
    attr_accessor :result_hash

    # @return [Boolean] finished if the fetch operation has completed
    attr_reader :finished

    # @return [Integer] The number of threads to use
    attr_accessor :thread_count

    # Perform a Riak Multiget operation.
    # @param [Client] client the {Riak::Client} that will perform the multiget
    # @param [Array<Bucket, String>] fetch_list an {Array} of {Bucket} and {String} keys to fetch
    # @return [Hash<fetch_list_entry, RObject] result_hash a {Hash} of {Bucket} and {String} key pairs to {Robject} instances
    def self.get_all(client, fetch_list)
      multi = new client, fetch_list
      multi.fetch
      multi.results
    end

    # Create a Riak Multiget operation.
    # @param [Client] client the {Riak::Client} that will perform the multiget
    # @param [Array<Bucket, String>] fetch_list an {Array} of {Bucket} and {String} keys to fetch
    def initialize(client, fetch_list)
      raise ArgumentError, t('client_type', client: client.inspect) unless client.is_a? Riak::Client
      raise ArgumentError, t('array_type', array: fetch_list.inspect) unless fetch_list.is_a? Array

      validate_fetch_list fetch_list
      @client, @fetch_list = client, fetch_list.uniq
      self.result_hash = Hash.new
      @finished = false
      self.thread_count = client.multiget_threads
    end

    # Starts the parallelized fetch operation
    # @raise [ArgumentError] when a non-positive-Integer count is given
    def fetch
      queue = fetch_list.dup
      mutex = Mutex.new

      unless thread_count.is_a?(Integer) && thread_count > 0
        raise ArgumentError, t("invalid_multiget_thread_count")
      end

      @threads = 1.upto(thread_count).map do |_node|
        Thread.new do
          loop do
            pair = mutex.synchronize do
              queue.shift
            end

            break if pair.nil?

            bucket, key = pair

            result_hash[pair] = bucket[key]
          end
        end
      end
    end

    def results
      wait_for_finish
      result_hash
    end

    def finished?
      set_finished_for_thread_liveness
      finished
    end

    def wait_for_finish
      return if finished?
      @threads.each {|t| t.join }
      @finished = true
    end

    private

    def set_finished_for_thread_liveness
      return if @finished # already done

      all_dead = @threads.none? {|t| t.alive? }
      return unless all_dead # still working

      @finished = true
      return
    end

    def validate_fetch_list(fetch_list)
      return unless erroneous = fetch_list.detect do |e|
        bucket, key = e
        next true unless bucket.is_a? Bucket
        next true unless key.is_a? String
      end

      raise ArgumentError, t('fetch_list_type', problem: erroneous)
    end
  end
end
