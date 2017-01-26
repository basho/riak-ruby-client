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

require 'riak/util/translation'
require 'riak/util/escape'
require 'riak/json'
require 'riak/client'
require 'riak/bucket'
require 'riak/robject'
require 'riak/bucket_typed/bucket'
require 'riak/walk_spec'
require 'riak/errors/failed_request'
require 'riak/errors/list_error'
require 'riak/map_reduce_error'
require 'riak/map_reduce/phase'
require 'riak/map_reduce/filter_builder'
require 'riak/map_reduce/results'

module Riak
  # Class for invoking map-reduce jobs using the HTTP interface.
  class MapReduce
    include Util::Translation
    include Util::Escape

    # @return [Array<[bucket,key]>,String,Hash<:bucket,:filters>] The
    #       bucket/keys for input to the job, or the bucket (all
    #       keys), or a hash containing the bucket and key-filters.
    # @see #add
    attr_accessor :inputs

    # @return [Array<Phase>] The map and reduce phases that will be executed
    # @see #map
    # @see #reduce
    # @see #link
    attr_accessor :query

    # Creates a new map-reduce job.
    # @param [Client] client the Riak::Client interface
    # @yield [self] helpful for initializing the job
    def initialize(client)
      @client, @inputs, @query = client, [], []
      yield self if block_given?
    end

    # Add or replace inputs for the job.
    # @overload add(bucket)
    #   Run the job across all keys in the bucket.  This will replace any other inputs previously added.
    #   @param [String, Bucket] bucket the bucket to run the job on
    # @overload add(bucket,key)
    #   Add a bucket/key pair to the job.
    #   @param [String,Bucket] bucket the bucket of the object
    #   @param [String] key the key of the object
    # @overload add(object)
    #   Add an object to the job (by its bucket/key)
    #   @param [RObject] object the object to add to the inputs
    # @overload add(bucket, key, keydata)
    #   @param [String,Bucket] bucket the bucket of the object
    #   @param [String] key the key of the object
    #   @param [String] keydata extra data to pass along with the object to the job
    # @overload add(bucket, filters)
    #   Run the job across all keys in the bucket, with the given
    #   key-filters. This will replace any other inputs previously
    #   added. (Requires Riak 0.14)
    #   @param [String,Bucket] bucket the bucket to filter keys from
    #   @param [Array<Array>] filters a list of key-filters to apply
    #                                 to the key list
    # @return [MapReduce] self
    def add(*params)
      params = params.dup
      params = params.first if Array === params.first
      case params.size
      when 1
        p = params.first
        case p
        when Bucket
          @inputs = bucket_input(p)
        when RObject
          @inputs << robject_input(p)
        when String
          maybe_raise_list_exception(caller)
          @inputs = maybe_escape(p)
        end
      when 2..3
        bucket = params.shift
        if Array === params.first
          if bucket.is_a? Bucket
            bucket = bucket_input(bucket)
          else
            bucket = maybe_escape(bucket)
          end
          maybe_raise_list_exception(caller)
          @inputs = {:bucket => bucket, :key_filters => params.first }
        else
          key = params.shift
          key_data = params.shift || ''
          @inputs << key_input(key, bucket, key_data)
        end
      end
      self
    end
    alias :<< :add
    alias :include :add

    # Adds a bucket and key-filters built by the given
    # block. Equivalent to #add with a list of filters.
    # @param [String] bucket the bucket to apply key-filters to
    # @yield [] builder block - instance_eval'ed into a FilterBuilder
    # @return [MapReduce] self
    # @see MapReduce#add
    def filter(bucket, &block)
      add(bucket, FilterBuilder.new(&block).to_a)
    end

    # (Riak Search) Use a search query to start a map/reduce job.
    # @param [String,Riak::Search::Index] index the index to query, either a
    #   {Riak::Search::Index} instance or a {String}
    # @param [String] query the query to run
    # @return [MapReduce] self
    def search(index, query)
      index = index.name if index.respond_to?(:name)
      @inputs = {:module => "yokozuna", :function => "mapred_search", :arg => [index, query]}
      self
    end

    # (Secondary Indexes) Use a secondary index query to start a
    # map/reduce job.
    # @param [String, Bucket] bucket the bucket whose index to query
    # @param [String] index the index to query
    # @param [String, Integer, Range] query the value of the index, or
    #   a range of values (of Strings or Integers)
    # @return [MapReduce] self
    def index(bucket, index, query)
      if bucket.is_a? Bucket
        bucket = bucket.needs_type? ? [maybe_escape(bucket.type.name), maybe_escape(bucket.name)] : maybe_escape(bucket.name)
      else
        bucket = maybe_escape(bucket)
      end

      case query
      when String, Fixnum
        @inputs = {:bucket => bucket, :index => index, :key => query}
      when Range
        raise ArgumentError, t('invalid_index_query', :value => query.inspect) unless String === query.begin || Integer === query.begin
        @inputs = {:bucket => bucket, :index => index, :start => query.begin, :end => query.end}
      else
        raise ArgumentError, t('invalid_index_query', :value => query.inspect)
      end
      self
    end

    # Add a map phase to the job.
    # @overload map(function)
    #   @param [String, Array] function a Javascript function that represents the phase, or an Erlang [module,function] pair
    # @overload map(function?, options)
    #   @param [String, Array] function a Javascript function that represents the phase, or an Erlang [module, function] pair
    #   @param [Hash] options extra options for the phase (see {Phase#initialize})
    # @return [MapReduce] self
    # @see Phase#initialize
    def map(*params)
      options = params.extract_options!
      @query << Phase.new({:type => :map, :function => params.shift}.merge(options))
      self
    end

    # Add a reduce phase to the job.
    # @overload reduce(function)
    #   @param [String, Array] function a Javascript function that represents the phase, or an Erlang [module,function] pair
    # @overload reduce(function?, options)
    #   @param [String, Array] function a Javascript function that represents the phase, or an Erlang [module, function] pair
    #   @param [Hash] options extra options for the phase (see {Phase#initialize})
    # @return [MapReduce] self
    # @see Phase#initialize
    def reduce(*params)
      options = params.extract_options!
      @query << Phase.new({:type => :reduce, :function => params.shift}.merge(options))
      self
    end

    # Add a link phase to the job. Link phases follow links attached to objects automatically (a special case of map).
    # @overload link(walk_spec, options={})
    #   @param [WalkSpec] walk_spec a WalkSpec that represents the types of links to follow
    #   @param [Hash] options extra options for the phase (see {Phase#initialize})
    # @overload link(bucket, tag, keep, options={})
    #   @param [String, nil] bucket the bucket to limit links to
    #   @param [String, nil] tag the tag to limit links to
    #   @param [Boolean] keep whether to keep results of this phase (overrides the phase options)
    #   @param [Hash] options extra options for the phase (see {Phase#initialize})
    # @overload link(options)
    #   @param [Hash] options options for both the walk spec and link phase
    #   @see WalkSpec#initialize
    # @return [MapReduce] self
    # @see Phase#initialize
    def link(*params)
      options = params.extract_options!
      walk_spec_options = options.slice!(:type, :function, :language, :arg) unless params.first
      walk_spec = WalkSpec.normalize(params.shift || walk_spec_options).first
      @query << Phase.new({:type => :link, :function => walk_spec}.merge(options))
      self
    end

    # Sets the timeout for the map-reduce job.
    # @param [Fixnum] value the job timeout, in milliseconds
    def timeout(value)
      @timeout = value
      return self
    end
    alias :timeout= :timeout

    # Convert the job to JSON for submission over the HTTP interface.
    # @return [String] the JSON representation
    def to_json(*a)
      hash = {"inputs" => inputs, "query" => query.map(&:as_json)}
      hash['timeout'] = @timeout.to_i if @timeout
      hash.to_json(*a)
    end

    # Executes this map-reduce job.
    # @overload run
    #   Return the entire collection of results.
    #   @return [Array<Array>] similar to link-walking, each element is
    #     an array of results from a phase where "keep" is true. If there
    #     is only one "keep" phase, only the results from that phase will
    #     be returned.
    # @overload run
    #   Stream the results through the given block without accumulating.
    #   @yield [phase, data] A block to stream results through
    #   @yieldparam [Fixnum] phase the phase from which the results were
    #          generated
    #   @yieldparam [Array] data a list of results from the phase
    #   @return [nil] nothing
    def run(&block)
      @client.mapred(self, &block)
    rescue FailedRequest => fr
      if fr.server_error? && fr.is_json?
        raise MapReduceError.new(fr.body)
      else
        raise fr
      end
    end

    private

    # Processes a {Bucket} or {BucketTyped::Bucket} into a whole-bucket
    # {MapReduce} input.
    def bucket_input(bucket)
      maybe_raise_list_exception(caller)
      if bucket.needs_type?
        return [maybe_escape(bucket.type.name), maybe_escape(bucket.name)]
      end
      maybe_escape(bucket.name)
    end

    # Processes a {RObject} into a single-object {MapReduce} input, whether it
    # has a bucket type or not.
    def robject_input(obj, key_data = '')
      bucket = obj.bucket
      if bucket.needs_type?
        return [
                maybe_escape(bucket.name),
                maybe_escape(obj.key),
                key_data,
                maybe_escape(bucket.type.name)
               ]
      end

      [maybe_escape(obj.bucket.name), maybe_escape(obj.key)]
    end

    # Processes a key into a single-object {MapReduce} input, doing the correct
    # thing if the bucket argument is a {String}, {Bucket}, or a
    # {BucketTyped::Bucket}.
    def key_input(key, bucket, key_data = '')
      kd = []
      kd << key_data unless key_data.blank?

      if bucket.is_a? String
        return [
                maybe_escape(bucket),
                maybe_escape(key)
               ] + kd
      elsif bucket.needs_type?
        return [
                maybe_escape(bucket.name),
                maybe_escape(key),
                key_data,
                maybe_escape(bucket.type.name)
               ]
      else
        return [
                maybe_escape(bucket.name),
                maybe_escape(key)
               ] + kd
      end
    end

    def maybe_raise_list_exception(bound_caller)
      unless Riak.disable_list_exceptions
        bt = bound_caller.join("\n    ")
        msg = t('full_bucket_mapred', :backtrace => bt)
        raise Riak::ListError.new(msg)
      end
    end
  end
end
