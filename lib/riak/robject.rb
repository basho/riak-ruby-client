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

require 'forwardable'
require 'riak/rcontent'
require 'riak/conflict'
require 'riak/tombstone'
require 'riak/util/translation'
require 'riak/util/escape'
require 'riak/bucket'
require 'riak/link'
require 'riak/walk_spec'

module Riak
  # Represents the data and metadata stored in a bucket/key pair in
  # the Riak database, the base unit of data manipulation.
  class RObject
    include Util::Translation
    extend Util::Translation
    include Util::Escape
    extend Util::Escape
    extend Forwardable

    # @return [Bucket] the bucket in which this object is contained
    attr_accessor :bucket

    # @return [String] the key of this object within its bucket
    attr_accessor :key

    # @return [String] the Riak causal context/vector clock for the object
    attr_accessor :vclock

    alias :causal_context :vclock
    alias :causal_context= :vclock=
    alias :vector_clock :vclock
    alias :vector_clock= :vclock=

    # @return [Boolean] whether to attempt to prevent stale writes using
    #   conditional PUT semantics, If-None-Match: * or If-Match: etag
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

    def_delegators :content, :content_type, :content_type=,
              :content_encoding, :content_encoding=,
              :links, :links=,
              :etag, :etag=,
              :last_modified, :last_modified=,
              :meta, :meta=,
              :indexes, :indexes=,
              :data, :data=,
              :raw_data, :raw_data=,
              :deserialize, :serialize,
              :decompress, :compress

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

    # Create a new object manually
    # @param [Bucket] bucket the bucket in which the object exists
    # @param [String] key the key at which the object resides. If nil, a key will be assigned when the object is saved.
    # @yield self the new RObject
    # @see Bucket#get
    def initialize(bucket, key = nil)
      @bucket, @key = bucket, key

      # fix a require-loop
      require 'riak/bucket_typed/bucket'

      if @bucket.is_a? BucketTyped::Bucket
        @type = @bucket.type.name
      end
      @siblings = [ RContent.new(self) ]
      yield self if block_given?
    end

    # Store the object in Riak
    # @param [Hash] options query parameters
    # @option options [Fixnum] :r the "r" parameter (Read quorum for the
    #   implicit read performed when validating the store operation)
    # @option options [Fixnum] :w the "w" parameter (Write quorum)
    # @option options [Fixnum] :dw the "dw" parameter (Durable-write quorum)
    # @option options [Boolean] :returnbody (true) whether to return the result
    #   of a successful write in the body of the response. Set to false for
    #   fire-and-forget updates, set to true to immediately have access to the
    #   object's stored representation.
    # @return [Riak::RObject] self
    # @raise [ArgumentError] if the content_type is not defined
    # @raise [Conflict] if the object has siblings
    def store(options = {})
      fail Conflict, self if conflict?
      fail Tombstone, self if tombstone?
      raise ArgumentError, t('content_type_undefined') unless content_type.present?
      raise ArgumentError, t('zero_length_key') if key == ''
      # NB: key can be nil to indicate that Riak should generate one
      unless key.nil? || key.is_a?(String)
        raise ArgumentError, t('string_type', :string => key)
      end
      @bucket.client.store_object(self, default(options))
      self
    end

    # Reload the object from Riak.  Will use conditional GETs when possible.
    # @param [Hash] options query parameters
    # @option options [Fixnum] :r the "r" parameter (Read quorum)
    # @option options [Boolean] :force will force a reload request if
    #     the vclock is not present, useful for reloading the object after
    #     a store (not passed in the query params)
    # @return [Riak::RObject] self
    def reload(options = {})
      force = options.delete(:force)
      return self unless @key && (@vclock || force)
      self.etag = self.last_modified = nil if force
      bucket.client.reload_object(self, default(options))
    end

    alias :fetch :reload

    # Delete the object from Riak and freeze this instance.  Will work whether or not the object actually
    # exists in the Riak database.
    # @see Bucket#delete
    def delete(options = {})
      return if key.blank?
      options[:vclock] = vclock if vclock
      @bucket.delete(key, default(options))
      freeze
    end

    # Returns sibling values. If the object is not in conflict, then
    # only one value will be present in the array.
    # @return [Array<RContent>] an array of conflicting sibling values
    #   for this key, possibly containing only one
    attr_accessor :siblings

    # Returns the solitary sibling when not in conflict.
    # @return [RContent] the sole value/sibling on this object
    # @raise [Conflict] when multiple siblings are present
    def content
      raise Conflict, self if conflict?
      raise Tombstone, self if tombstone?
      @siblings.first
    end

    # @return [true,false] Whether this object has conflicting sibling objects (divergent vclocks)
    def conflict?
      @siblings.size > 1
    end

    # @return [true,false] Whether this object is a Riak tombstone (has no RContents, but contains a vclock)
    def tombstone?
      @siblings.empty? && !@vclock.nil?
    end

    # Will "revive" a tombstone object by giving it a new content.
    # If the object is not a tombstone, will just return self.
    # @return [Riak::RObject] self
    def revive
      @siblings = [ RContent.new(self) ] if tombstone?
      self
    end

    # @return [String] A representation suitable for IRB and debugging output
    def inspect
      body = @siblings.map {|s| s.inspect }.join(", ")
      "#<#{self.class.name} {#{bucket.name}#{"," + @key if @key}} [#{body}]>"
    end

    # Converts the object to a link suitable for linking other objects
    # to it
    # @param [String] tag the tag to apply to the link
    def to_link(tag)
      Link.new(@bucket.name, @key, tag)
    end

    # Retrieves a preflist for this RObject; useful for
    # figuring out where in the cluster it is stored.
    # @return [Array<PreflistItem>] an array of preflist entries
    def preflist(options = {})
      bucket.get_preflist key, options
    end

    private

    def default(options)
      return options unless options.is_a? Hash
      return options unless @type

      {type: @type}.merge options
    end
  end
end
