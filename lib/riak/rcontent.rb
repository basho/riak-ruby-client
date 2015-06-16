require 'set'
require 'time'
require 'yaml'
require 'forwardable'
require 'riak/util/translation'
require 'riak/serializers'

module Riak
  # Represents single (potentially-conflicted) value stored against a
  # key in the Riak database. This includes the raw value as well as
  # metadata.
  # @since 1.1.0
  class RContent
    extend Forwardable
    include Util::Translation

    # @return [String] the MIME content type of the value
    attr_accessor :content_type

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

    # @return [Riak::RObject] the RObject to which this sibling belongs
    attr_accessor :robject

    def_delegators :robject, :bucket, :key, :vclock

    # Creates a new object value. This should not normally need to be
    # called by users of the client. Normal, single-value use can rely
    # on the delegating accessors on {Riak::RObject}.
    # @param [RObject] robject the object that this value belongs to
    # @yield self the new RContent
    def initialize(robject)
      @robject = robject
      @links, @meta = Set.new, {}
      @indexes = new_index_hash
      yield self if block_given?
    end

    def indexes=(hash)
      @indexes = hash.inject(new_index_hash) do |h, (k, v)|
        h[k].merge([*v])
        h
      end
    end

    # @return [Object] the unmarshaled form of {#raw_data} stored in riak at
    #   this object's key
    def data
      if @raw_data && !@data
        raw = @raw_data.respond_to?(:read) ? @raw_data.read : @raw_data
        @data = deserialize(raw)
        @raw_data = nil
      end
      @data
    end

    # @param [Object] new_data unmarshaled form of the data to be stored in
    #   Riak. Object will be serialized using {#serialize} if a known
    #   content_type is used. Setting this overrides values stored with
    #   {#raw_data=}
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

    # @param [String, IO-like] new_raw_data the raw data to be stored in Riak
    #   at this key, will not be marshaled or manipulated prior to storage.
    #   Overrides any data stored by {#data=}
    # @return [String] the data stored
    def raw_data=(new_raw_data)
      @data = nil
      @raw_data = new_raw_data
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
      "#<#{self.class.name} [#{@content_type}]:#{body}>"
    end

    # @api private
    def load_map_reduce_value(hash)
      metadata = hash['metadata']
      extract_if_present(metadata, 'X-Riak-VTag', :etag)
      extract_if_present(metadata, 'content-type', :content_type)
      extract_if_present(metadata, 'X-Riak-Last-Modified', :last_modified) { |v| Time.httpdate( v ) }
      extract_if_present(metadata, 'index', :indexes) do |entries|
        Hash[ entries.map {|k, v| [k, Set.new(Array(v))] } ]
      end
      extract_if_present(metadata, 'Links', :links) do |links|
        Set.new( links.map { |l| Link.new(*l) } )
      end
      extract_if_present(metadata, 'X-Riak-Meta', :meta) do |meta|
        Hash[
             meta.map do |k, v|
               [k.sub(%r{^x-riak-meta-}i, ''), [v]]
             end
            ]
      end
      extract_if_present(hash, 'data', :data) { |v| deserialize(v) }
    end

    private
    def extract_if_present(hash, key, attribute = nil)
      if hash[key].present?
        attribute ||= key
        value = block_given? ? yield(hash[key]) : hash[key]
        send("#{attribute}=", value)
      end
    end

    def new_index_hash
      Hash.new {|h, k| h[k] = Set.new }
    end
  end
end
