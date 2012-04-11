require 'set'
require 'time'
require 'yaml'
require 'riak/util/translation'
require 'riak/util/escape'
require 'riak/bucket'
require 'riak/link'
require 'riak/walk_spec'
require 'riak/serializers'

module Riak
  # Represents the data and metadata stored in a bucket/key pair in
  # the Riak database, the base unit of data manipulation.
  class RObject
    include Util::Translation
    extend  Util::Translation
    include Util::Escape
    extend Util::Escape

    # @return [Bucket] the bucket in which this object is contained
    attr_accessor :bucket

    # @return [String] the key of this object within its bucket
    attr_accessor :key

    # @return [String] the MIME content type of the object
    attr_accessor :content_type

    # @return [String] the Riak vector clock for the object
    attr_accessor :vclock

    # @return [Set<Link>] a Set of {Riak::Link} objects for relationships between this object and other resources
    attr_accessor :links

    # @return [String] the ETag header from the most recent HTTP response, useful for caching and reloading
    attr_accessor :etag

    # @return [Time] the Last-Modified header from the most recent HTTP response, useful for caching and reloading
    attr_accessor :last_modified

    # @return [Hash] a hash of any X-Riak-Meta-* headers that were in the HTTP response, keyed on the trailing portion
    attr_accessor :meta

    # @return [Hash<Set>] a hash of secondary indexes, where the
    #   key is the index name and the value is a Set of index
    #   entries for that index
    attr_accessor :indexes

    # @return [Boolean] whether to attempt to prevent stale writes using conditional PUT semantics, If-None-Match: * or If-Match: {#etag}
    # @see http://wiki.basho.com/display/RIAK/REST+API#RESTAPI-Storeaneworexistingobjectwithakey Riak Rest API Docs
    attr_accessor :prevent_stale_writes

    # Defines a callback to be invoked when there is conflict.
    #
    # @yield The conflict callback.
    # @yieldparam [RObject] robject The conflicted RObject
    # @yieldreturn [RObject, nil] Either the resolved RObject or nil if your
    #                             callback cannot resolve it. The next registered
    #                             callback will be given the chance to resolve it.
    #
    # @note Ripple registers its own document-level conflict handler, so if you're
    #       using ripple, you will probably want to use that instead.
    def self.on_conflict(&conflict_hook)
      on_conflict_hooks << conflict_hook
    end

    # @return [Array<Proc>] the list of registered conflict callbacks.
    def self.on_conflict_hooks
      @on_conflict_hooks ||= []
    end

    # Attempts to resolve conflict using the registered conflict callbacks.
    #
    # @return [RObject] the RObject
    # @note There is no guarantee the returned RObject will have been resolved
    def attempt_conflict_resolution
      return self unless conflict?

      self.class.on_conflict_hooks.each do |hook|
        result = hook.call(self)
        return result if result.is_a?(RObject)
      end

      self
    end

    # Loads a list of RObjects that were emitted from a MapReduce
    # query.
    # @param [Client] client A Riak::Client with which the results will be associated
    # @param [Array<Hash>] response A list of results a MapReduce job. Each entry should contain these keys: bucket, key, vclock, values
    # @return [Array<RObject>] An array of RObject instances
    def self.load_from_mapreduce(client, response)
      response.map do |item|
        RObject.new(client[unescape(item['bucket'])], unescape(item['key'])).load_from_mapreduce(item)
      end
    end

    # Create a new object manually
    # @param [Bucket] bucket the bucket in which the object exists
    # @param [String] key the key at which the object resides. If nil, a key will be assigned when the object is saved.
    # @yield self the new RObject
    # @see Bucket#get
    def initialize(bucket, key=nil)
      @bucket, @key = bucket, key
      @links, @meta = Set.new, {}
      @indexes = new_index_hash
      yield self if block_given?
    end

    def indexes=(hash)
      @indexes = hash.inject(new_index_hash) do |h, (k,v)|
        h[k].merge([*v])
        h
      end
    end

    # Load object data from a map/reduce response item.
    # This method is used by RObject::load_from_mapreduce to instantiate the necessary
    # objects.
    # @param [Hash] response a response from {Riak::MapReduce}
    # @return [RObject] self
    def load_from_mapreduce(response)
      self.vclock = response['vclock']
      if response['values'].size == 1
        value = response['values'].first
        load_map_reduce_value(value)
      else
        @conflict = true
        @siblings = response['values'].map do |v|
          RObject.new(self.bucket, self.key) do |robj|
            robj.vclock = self.vclock
            robj.load_map_reduce_value(v)
          end
        end
      end
      self
    end

    # @return [Object] the unmarshaled form of {#raw_data} stored in riak at this object's key
    def data
      if @raw_data && !@data
        raw = @raw_data.respond_to?(:read) ? @raw_data.read : @raw_data
        @data = deserialize(raw)
        @raw_data = nil
      end
      @data
    end

    # @param [Object] unmarshaled form of the data to be stored in riak. Object will be serialized using {#serialize} if a known content_type is used. Setting this overrides values stored with {#raw_data=}
    # @return [Object] the object stored
    def data=(new_data)
      if new_data.respond_to?(:read)
        raise ArgumentError.new(t("invalid_io_object"))
      end

      @raw_data = nil
      @data = new_data
    end

    # @return [String] raw data stored in riak for this object's key
    def raw_data
      if @data && !@raw_data
        @raw_data = serialize(@data)
        @data = nil
      end
      @raw_data
    end

    # @param [String, IO-like] the raw data to be stored in riak at this key, will not be marshaled or manipulated prior to storage. Overrides any data stored by {#data=}
    # @return [String] the data stored
    def raw_data=(new_raw_data)
      @data = nil
      @raw_data = new_raw_data
    end

    # Store the object in Riak
    # @param [Hash] options query parameters
    # @option options [Fixnum] :r the "r" parameter (Read quorum for the implicit read performed when validating the store operation)
    # @option options [Fixnum] :w the "w" parameter (Write quorum)
    # @option options [Fixnum] :dw the "dw" parameter (Durable-write quorum)
    # @option options [Boolean] :returnbody (true) whether to return the result of a successful write in the body of the response. Set to false for fire-and-forget updates, set to true to immediately have access to the object's stored representation.
    # @return [Riak::RObject] self
    # @raise [ArgumentError] if the content_type is not defined
    def store(options={})
      raise ArgumentError, t("content_type_undefined") unless @content_type.present?
      @bucket.client.store_object(self, options)
      self
    end

    # Reload the object from Riak.  Will use conditional GETs when possible.
    # @param [Hash] options query parameters
    # @option options [Fixnum] :r the "r" parameter (Read quorum)
    # @option options [Boolean] :force will force a reload request if
    #     the vclock is not present, useful for reloading the object after
    #     a store (not passed in the query params)
    # @return [Riak::RObject] self
    def reload(options={})
      force = options.delete(:force)
      return self unless @key && (@vclock || force)
      self.etag = self.last_modified = nil if force
      bucket.client.reload_object(self, options)
    end

    alias :fetch :reload

    # Delete the object from Riak and freeze this instance.  Will work whether or not the object actually
    # exists in the Riak database.
    # @see Bucket#delete
    def delete(options={})
      return if key.blank?
      options[:vclock] = vclock if vclock
      @bucket.delete(key, options)
      freeze
    end

    attr_writer :siblings, :conflict

    # Returns sibling objects when in conflict.
    # @return [Array<RObject>] an array of conflicting sibling objects for this key
    # @return [Array<self>] a single-element array containing object when not
    # in conflict
    def siblings
      return [self] unless conflict?
      @siblings
    end

    # @return [true,false] Whether this object has conflicting sibling objects (divergent vclocks)
    def conflict?
      @conflict.present?
    end

    # Serializes the internal object data for sending to Riak. Differs based on the content-type.
    # This method is called internally when storing the object.
    # Automatically serialized formats:
    # * JSON (application/json)
    # * YAML (text/yaml)
    # * Marshal (application/x-ruby-marshal)
    # When given an IO-like object (e.g. File), no serialization will
    # be done.
    # @param [Object] payload the data to serialize
    def serialize(payload)
      Serializers.serialize(@content_type, payload)
    end

    # Deserializes the internal object data from a Riak response. Differs based on the content-type.
    # This method is called internally when loading the object.
    # Automatically deserialized formats:
    # * JSON (application/json)
    # * YAML (text/yaml)
    # * Marshal (application/x-ruby-marshal)
    # @param [String] body the serialized response body
    def deserialize(body)
      Serializers.deserialize(@content_type, body)
    end

    # @return [String] A representation suitable for IRB and debugging output
    def inspect
      body = if @data || Serializers[content_type]
               data.inspect
             else
               @raw_data && "(#{@raw_data.size} bytes)"
             end
      "#<#{self.class.name} {#{bucket.name}#{"," + @key if @key}} [#{@content_type}]:#{body}>"
    end

    # Walks links from this object to other objects in Riak.
    # @param [Array<Hash,WalkSpec>] link specifications for the query
    def walk(*params)
      specs = WalkSpec.normalize(*params)
      @bucket.client.link_walk(self, specs)
    end

    # Converts the object to a link suitable for linking other objects
    # to it
    # @param [String] tag the tag to apply to the link
    def to_link(tag)
      Link.new(@bucket.name, @key, tag)
    end

    alias :vector_clock :vclock
    alias :vector_clock= :vclock=

    protected
    def load_map_reduce_value(hash)
      metadata = hash['metadata']
      extract_if_present(metadata, 'X-Riak-VTag', :etag)
      extract_if_present(metadata, 'content-type', :content_type)
      extract_if_present(metadata, 'X-Riak-Last-Modified', :last_modified) { |v| Time.httpdate( v ) }
      extract_if_present(metadata, 'index', :indexes) do |entries|
        Hash[ entries.map {|k,v| [k, Set.new(Array(v))] } ]
      end
      extract_if_present(metadata, 'Links', :links) do |links|
        Set.new( links.map { |l| Link.new(*l) } )
      end
      extract_if_present(metadata, 'X-Riak-Meta', :meta) do |meta|
        Hash[
             meta.map do |k,v|
               [k.sub(%r{^x-riak-meta-}i, ''), [v]]
             end
            ]
      end
      extract_if_present(hash, 'data', :data) { |v| deserialize(v) }
    end

    private
    def extract_if_present(hash, key, attribute=nil)
      if hash[key].present?
        attribute ||= key
        value = block_given? ? yield(hash[key]) : hash[key]
        send("#{attribute}=", value)
      end
    end

    def new_index_hash
      Hash.new {|h,k| h[k] = Set.new }
    end
  end
end
