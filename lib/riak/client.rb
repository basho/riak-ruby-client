# Copyright 2010-present Basho Technologies, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'tempfile'
require 'delegate'
require 'innertube'
require 'riak'
require 'riak/util/translation'
require 'riak/util/escape'
require 'riak/errors/backend_creation'
require 'riak/errors/failed_request'
require 'riak/errors/list_error'
require 'riak/errors/protobuffs_error'
require 'riak/client/decaying'
require 'riak/client/node'
require 'riak/client/search'
require 'riak/client/yokozuna'
require 'riak/client/protobuffs_backend'
require 'riak/preflist_item'
require 'riak/client/beefcake_protobuffs_backend'
require 'riak/bucket'
require 'riak/bucket_properties'
require 'riak/bucket_type'
require 'riak/multiget'
require 'riak/multiexist'
require 'riak/secondary_index'
require 'riak/search'
require 'riak/stamp'
require 'riak/time_series'
require 'riak/list_buckets'

module Riak
  # A client connection to Riak.
  class Client
    include Util::Translation
    include Util::Escape

    # When using integer client IDs, the exclusive upper-bound of valid values.
    MAX_CLIENT_ID = 4294967296

    # Regexp for validating hostnames, lifted from uri.rb in Ruby 1.8.6
    HOST_REGEX = /^(?:(?:(?:[a-zA-Z\d](?:[-a-zA-Z\d]*[a-zA-Z\d])?)\.)*(?:[a-zA-Z](?:[-a-zA-Z\d]*[a-zA-Z\d])?)\.?|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|\[(?:(?:[a-fA-F\d]{1,4}:)*(?:[a-fA-F\d]{1,4}|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})|(?:(?:[a-fA-F\d]{1,4}:)*[a-fA-F\d]{1,4})?::(?:(?:[a-fA-F\d]{1,4}:)*(?:[a-fA-F\d]{1,4}|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}))?)\])$/n

    # Valid constructor options.
    VALID_OPTIONS = [:nodes, :client_id, :protobuffs_backend, :authentication, :max_retries, :connect_timeout, :read_timeout, :write_timeout, :convert_timestamp] | Node::VALID_OPTIONS

    # Network errors.
    NETWORK_ERRORS = [
      EOFError,
      Errno::ECONNABORTED,
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Errno::ENETDOWN,
      Errno::ENETRESET,
      Errno::ENETUNREACH,
      Errno::ETIMEDOUT,
      SocketError,
      SystemCallError,
      Riak::ProtobuffsFailedHeader,
    ]

    Pool = ::Innertube::Pool

    # @return [Array] The set of Nodes this client can communicate with.
    attr_accessor :nodes

    # @return [String] The internal client ID used by Riak to route responses
    attr_reader :client_id

    # @return [Symbol] The Protocol Buffers backend/client to use
    attr_accessor :protobuffs_backend

    # @return [Client::Pool] A pool of protobuffs connections
    attr_reader :protobuffs_pool

    # @return [Integer] The number of threads for multiget requests
    attr_reader :multi_threads

    # @deprecated use multi_threads
    alias_method :multiget_threads, :multi_threads

    # @return [Hash] The authentication information this client will use.
    attr_reader :authentication

    # @return [Integer] The maximum number of retries in case of NETWORK_ERRORS
    attr_accessor :max_retries

    # @return [Numeric] The connect timeout, in seconds
    attr_reader :connect_timeout

    # @return [Numeric] The read timeout, in seconds
    attr_reader :read_timeout

    # @return [Numeric] The write timeout, in seconds
    attr_reader :write_timeout

    # @return [Boolean] Convert timestamps from Riak TS to Time objects
    attr_reader :convert_timestamp

    # Creates a client connection to Riak
    # @param [Hash] options configuration options for the client
    # @option options [Array] :nodes A list of nodes this client connects to.
    #   Each element of the list is a hash which is passed to Node.new, e.g.
    #   `{host: '127.0.0.1', pb_port: 1234, ...}`.
    #   If no nodes are given, a single node is constructed from the remaining
    #   options given to Client.new.
    # @option options [String] :host ('127.0.0.1') The host or IP address for the Riak endpoint
    # @option options [Fixnum] :pb_port (8087) The port of the Riak Protocol Buffers endpoint
    # @option options [Fixnum, String] :client_id (rand(MAX_CLIENT_ID)) The internal client ID used by Riak to route responses
    # @option options [String, Symbol] :protobuffs_backend (:Beefcake) which Protocol Buffers backend to use
    # @option options [Fixnum]  :max_retries (2) The maximum number of retries in case of NETWORK_ERRORS
    # @option options [Numeric] :connect_timeout (nil) The connect timeout, in seconds
    # @option options [Numeric] :read_timeout (nil) The read timeout, in seconds
    # @option options [Numeric] :write_timeout (nil) The write timeout, in seconds
    # @raise [ArgumentError] raised if any invalid options are given
    def initialize(options = {})
      if options.include? :port
        warn(t('deprecated.port', :backtrace => caller[0..2].join("\n    ")))
      end

      unless (evil = options.keys - VALID_OPTIONS).empty?
        raise ArgumentError, "#{evil.inspect} are not valid options for Client.new"
      end

      @nodes = build_nodes(options)

      @protobuffs_pool = Pool.new(
                                  method(:new_protobuffs_backend),
                                  lambda { |b| b.teardown }
                                  )

      self.protobuffs_backend = options[:protobuffs_backend] || :Beefcake
      self.client_id          = options[:client_id]          if options[:client_id]
      self.multi_threads      = options[:multi_threads] || options[:multiget_threads]
      @authentication         = options[:authentication] && options[:authentication].symbolize_keys
      self.max_retries        = options[:max_retries]        || 2
      @connect_timeout        = options[:connect_timeout]
      @read_timeout           = options[:read_timeout]
      @write_timeout          = options[:write_timeout]
      @convert_timestamp      = options[:convert_timestamp]  || false
    end

    # Is security enabled?
    # @return [Boolean] whether or not a secure connection is being used
    def security?
      !!authentication
    end

    # Retrieves a bucket from Riak.
    # @param [String] name the bucket to retrieve
    # @param [Hash] options options for retrieving the bucket
    # @option options [Boolean] :props (false) whether to retreive the bucket properties
    # @return [Bucket] the requested bucket
    def bucket(name, options = {})
      raise ArgumentError, t('zero_length_bucket') if name == ''
      unless (options.keys - [:props]).empty?
        raise ArgumentError, "invalid options"
      end
      @bucket_cache ||= {}
      (@bucket_cache[name] ||= Bucket.new(self, name)).tap do |b|
        b.props if options[:props]
      end
    end
    alias :[] :bucket

    def bucket_type(name)
      BucketType.new self, name
    end

    # Lists buckets which have keys stored in them.
    # @note This is an expensive operation and should be used only
    #       in development.
    # @return [Array<Bucket>] a list of buckets
    def buckets(options = {}, &block)
      unless Riak.disable_list_exceptions
        msg = warn(t('list_buckets', :backtrace => caller.join("\n    ")))
        raise Riak::ListError.new(msg)
      end

      return ListBuckets.new self, options, block if block_given?

      backend do |b|
        b.list_buckets(options).map {|name| Bucket.new(self, name) }
      end
    end
    alias :list_buckets :buckets

    # Choose a node from a set.
    def choose_node(nodes = self.nodes)
      # Prefer nodes which have gone a reasonable time without errors.
      s = nodes.select do |node|
        node.error_rate.value < 0.1
      end

      if s.empty?
        # Fall back to minimally broken node.
        nodes.min_by do |node|
          node.error_rate.value
        end
      else
        s[rand(s.size)]
      end
    end

    # Set the number of threads to use for multiget operations.
    # If set to nil, defaults to twice the number of nodes.
    # @param [Integer] count The number of threads to use.
    # @raise [ArgumentError] when a non-nil, non-positive-Integer count is given
    def multi_threads=(count)
      if count.nil?
        @multi_threads = nodes.length * 2
        return
      end

      if count.is_a?(Integer) && count > 0
        @multi_threads = count
        return
      end

      raise ArgumentError, t("invalid_multiget_thread_count") # TODO: rename to invalid_multi_thread_count
    end

    # @deprecated use multi_threads=
    alias_method :multiget_threads=, :multi_threads=

    # Set the client ID for this client. Must be a string or Fixnum value 0 =<
    # value < MAX_CLIENT_ID.
    # @param [String, Fixnum] value The internal client ID used by Riak to route responses
    # @raise [ArgumentError] when an invalid client ID is given
    # @return [String] the assigned client ID
    def client_id=(value)
      value = case value
              when 0...MAX_CLIENT_ID, String
                value
              else
                raise ArgumentError, t("invalid_client_id", :max_id => MAX_CLIENT_ID)
              end

      # Change all existing backend client IDs.
      @protobuffs_pool.each do |pb|
        pb.set_client_id value if pb.respond_to?(:set_client_id)
      end
      @client_id = value
    end

    def client_id
      @client_id ||= backend do |b|
        if b.respond_to?(:get_client_id)
          b.get_client_id
        else
          make_client_id
        end
      end
    end

    # Delete an object. See Bucket#delete
    def delete_object(bucket, key, options = {})
      backend do |b|
        b.delete_object(bucket, key, options)
      end
    end

    # Bucket properties. See Bucket#props
    def get_bucket_props(bucket, options = {  })
      backend do |b|
        b.get_bucket_props bucket, options
      end
    end

    # Queries a secondary index on a bucket. See Bucket#get_index
    def get_index(bucket, index, query, options = {})
      backend do |b|
        b.get_index bucket, index, query, options
      end
    end

    # Retrieves a preflist for the given bucket, key, and type; useful for
    # figuring out where in the cluster an object is stored.
    # @param [Bucket, String] bucket the Bucket or name of the bucket
    # @param [String] key the key
    # @param [BucketType, String] type the bucket type or name of the bucket
    #   type
    # @return [Array<PreflistItem>] an array of preflist entries
    def get_preflist(bucket, key, type = nil, options = {  })
      backend do |b|
        b.get_preflist bucket, key, type, options
      end
    end

    # Get multiple objects in parallel.
    def get_many(pairs)
      Multiget.perform self, pairs
    end

    # Get an object. See Bucket#get
    def get_object(bucket, key, options = {})
      raise ArgumentError, t('zero_length_key') if key == ''
      raise ArgumentError, t('string_type', :string => key) unless key.is_a? String
      backend do |b|
        b.fetch_object(bucket, key, options)
      end
    end

    # @return [String] A representation suitable for IRB and debugging output.
    def inspect
      "#<Riak::Client #{nodes.inspect}>"
    end

    # Retrieves a list of keys in the given bucket. See Bucket#keys
    def list_keys(bucket, options = {}, &block)
      if block_given?
        backend do |b|
          b.list_keys bucket, options, &block
        end
      else
        backend do |b|
          b.list_keys bucket, options
        end
      end
    end

    # Executes a mapreduce request. See MapReduce#run
    def mapred(mr, &block)
      backend do |b|
        b.mapred(mr, &block)
      end
    end

    # Creates a new protocol buffers backend.
    # @return [ProtobuffsBackend] the Protocol Buffers backend for
    #    a given node.
    def new_protobuffs_backend
      klass = self.class.const_get("#{@protobuffs_backend}ProtobuffsBackend")
      unless klass.configured?
        raise BackendCreationError.new @protobuffs_backend
      end
      node = choose_node(
        @nodes.select do |n|
          n.protobuffs?
        end
      )

      klass.new(self, node)
    end

    # @return [Node] An arbitrary Node.
    def node
      nodes[rand nodes.size]
    end

    # Pings the Riak cluster to check for liveness.
    # @return [true,false] whether the Riak cluster is alive and reachable
    def ping
      backend do |b|
        b.ping
      end
    end

    # Yields a protocol buffers backend.
    def protobuffs(&block)
      recover_from @protobuffs_pool, &block
    end
    alias :backend :protobuffs

    # Sets the desired Protocol Buffers backend
    def protobuffs_backend=(value)
      # Shutdown any connections using the old backend
      @protobuffs_backend = value
      @protobuffs_pool.clear
      @protobuffs_backend
    end

    # Takes a pool. Acquires a backend from the pool and yields it with
    # node-specific error recovery.
    def recover_from(pool)
      skip_nodes = []
      take_opts = {}
      tries = 1 + max_retries

      begin
        # Only select nodes which we haven't used before.
        unless skip_nodes.empty?
          take_opts[:filter] = lambda do |backend|
            not skip_nodes.include? backend.node
          end
        end

        # Acquire a backend
        pool.take(take_opts) do |backend|
          begin
            yield backend
          rescue *NETWORK_ERRORS => e
            Riak.logger.warn("Riak client error: #{e.inspect} for #{backend.inspect}")

            # Network error.
            tries -= 1

            # Notify the node that a request against it failed.
            backend.node.error_rate << 1

            # Skip this node next time.
            skip_nodes << backend.node

            # And delete this connection.
            raise Pool::BadResource, e
          end
        end
      rescue Pool::BadResource => e
        retry if tries > 0
        raise e.message
      end
    end

    # Reloads the object from Riak.
    def reload_object(object, options = {})
      backend do |b|
        b.reload_object(object, options)
      end
    end

    # Sets the properties on a bucket. See Bucket#props=
    def set_bucket_props(bucket, properties, type = nil)
      backend do |b|
        b.set_bucket_props(bucket, properties, type)
      end
    end

    # Clears the properties on a bucket. See Bucket#clear_props
    def clear_bucket_props(bucket, options = {  })
      backend do |b|
        b.reset_bucket_props(bucket, options)
      end
    end

    # Exposes a {Stamp} object for use in generating unique
    # identifiers.
    # @return [Stamp] an ID generator
    # @see Stamp#next
    def stamp
      @stamp ||= Riak::Stamp.new(self)
    end


    # Stores an object in Riak.
    def store_object(object, options = {})
      params = {:returnbody => true}.merge(options)
      backend do |b|
        b.store_object(object, params)
      end
    end

    private
    def make_client_id
      rand(MAX_CLIENT_ID)
    end

    def ssl_enable
      @nodes.each do |n|
        n.ssl_enable
      end
    end

    def ssl_disable
      @nodes.each do |n|
        n.ssl_disable
      end
    end

    def build_nodes(options)
      if options.key?(:nodes) and !options[:nodes].empty?
        options[:nodes].map do |n|
          if !n.key?(:pb_port) and options.key?(:pb_port)
            n[:pb_port] = options[:pb_port]
          end
          Client::Node.new self, n
        end
      else
        [Client::Node.new(self, options)]
      end
    end
  end
end
