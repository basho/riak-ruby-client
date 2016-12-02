require 'riak/client'
require 'riak/bucket'

module Riak
  # Coordinates a parallel operation for multiple keys.
  class Multi
    include Util::Translation

    # @return [Riak::Client] the associated client
    attr_reader :client

    # @return [Array<Bucket, String>] fetch_list an {Array} of {Bucket} and {String} keys
    attr_reader :keys

    # @return [Hash<fetch_list_entry, RObject] result_hash a {Hash} of {Bucket} and {String} key pairs to {RObject} instances
    attr_accessor :result_hash

    # @return [Integer] The number of threads to use
    attr_accessor :thread_count

    # Perform a Riak Multi operation.
    # @param [Client] client the {Riak::Client} that will perform the operation
    # @param [Array<Bucket, String>] keys an {Array} of {Bucket} and {String} keys to work with
    # @return [Hash<key, RObject] result_hash a {Hash} of {Bucket} and {String} key pairs to {RObject} instances
    def self.perform(client, keys)
      multi = new client, keys
      multi.perform
      multi.results
    end

    # Create a Riak Multi operation.
    # @param [Client] client the {Riak::Client} that will perform the multiget
    # @param [Array<Bucket, String>] keys an {Array} of {Bucket} and {String} keys to work on
    # @raise [ArgumentError] when a non-positive-Integer count is given for threads
    def initialize(client, keys)
      raise ArgumentError, t('client_type', :client => client.inspect) unless client.is_a? Riak::Client
      raise ArgumentError, t('array_type', :array => keys.inspect) unless keys.is_a? Array

      self.thread_count = client.multi_threads
      unless thread_count.is_a?(Integer) && thread_count > 0
        raise ArgumentError, t("invalid_multiget_thread_count") # TODO: should be invalid_multi_thread_count
      end

      validate_keys keys
      @client = client
      @keys = keys.uniq
      self.result_hash = {}
      @finished = false
    end

    # Starts the parallelized operation
    def perform
      queue = keys.dup
      queue_mutex = Mutex.new
      result_mutex = Mutex.new

      @threads = 1.upto(thread_count).map do |_node|
        Thread.new do
          loop do
            pair = queue_mutex.synchronize do
              queue.shift
            end

            break if pair.nil?

            found = work(*pair)
            result_mutex.synchronize do
              result_hash[pair] = found
            end
          end
        end
      end
    end

    def results
      wait_for_finish
      result_hash
    end

    def finished?
      @finished ||= @threads && @threads.none?(&:alive?)
    end
    alias :finished :finished? # deprecated

    def wait_for_finish
      return if finished?
      @threads.each(&:join)
      @finished = true
    end

    private

    def work(_bucket, _key)
      raise NotImplementedError
    end

    def validate_keys(keys)
      erroneous = keys.detect do |bucket, key|
        !bucket.is_a?(Bucket) || !key.is_a?(String)
      end
      return unless erroneous
      raise ArgumentError, t('fetch_list_type', problem: erroneous) # TODO: should be keys_type
    end
  end
end
