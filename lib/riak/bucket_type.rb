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

require 'riak/util/string'
require 'riak/bucket_typed/bucket'
require 'riak/errors/crdt_error'

module Riak
  # A representation of a bucket type
  class BucketType
    include Util::String

    attr_reader :client, :name

    # The name of Riak's default bucket type.
    DEFAULT_NAME = 'default'

    # Create a bucket type object manually.
    # @param [Client] client the {Riak::Client} for this bucket type
    # @param [String] name the name of this bucket type
    def initialize(client, name)
      @client, @name = client, name
    end

    # Is this bucket type the default?
    # @return [Boolean]
    def default?
      name == DEFAULT_NAME
    end

    # Get a bucket of this type
    # @param [String] bucket_name the name of this bucket
    def bucket(bucket_name)
      BucketTyped::Bucket.new client, bucket_name, self
    end

    # Pretty prints the bucket for `pp` or `pry`.
    def pretty_print(pp)
      pp.object_group self do
        pp.breakable
        pp.text "name=#{name}"
      end
    end

    # Sets internal properties on the bucket type
    # Note: this results in a request to the Riak server!
    # @param [Hash] properties new properties for the bucket type
    # @option properties [Fixnum] :n_val (3) The N value (replication factor)
    # @option properties [true,false] :allow_mult (false) Whether to permit object siblings
    # @option properties [true,false] :last_write_wins (false) Whether to ignore
    #   causal context in regular key-value buckets
    # @option properties [Array<Hash>] :precommit ([]) precommit hooks
    # @option properties [Array<Hash>] :postcommit ([])postcommit hooks
    # @option properties [Fixnum,String] :r ("quorum") read quorum (numeric or
    # symbolic)
    # @option properties [Fixnum,String] :w ("quorum") write quorum (numeric or
    # symbolic)
    # @option properties [Fixnum,String] :dw ("quorum") durable write quorum
    # (numeric or symbolic)
    # @option properties [Fixnum,String] :rw ("quorum") delete quorum (numeric or
    # symbolic)
    # @return [Hash] the merged bucket properties
    # @raise [FailedRequest] if the new properties were not accepted by the Riakserver
    # @see #n_value, #allow_mult, #r, #w, #dw, #rw
    def props=(properties)
      raise ArgumentError, t("hash_type", :hash => properties.inspect) unless properties.is_a? Hash
      props.merge!(properties)
      @client.set_bucket_type_props(self, properties)
      props
    end
    alias :'properties=' :'props='

    # Get the properties of this bucket type
    # @return [Hash<Symbol,Object>]
    def props
      @prope ||= @client.get_bucket_type_props(self)
    end
    alias :properties :props

    # Return the data type used for handling the CRDT stored in this bucket
    # type.
    # Returns `nil` for a non-CRDT bucket type.
    # @raise [Riak::CrdtError::UnrecognizedDataType] if the bucket type has an
    #   unknown datatype
    # @return [Class<Riak::Crdt::Base>] CRDT subclass to use with this bucket
    #   type
    def data_type_class
      return nil unless dt = properties[:datatype]
      parent = Riak::Crdt
      case dt
      when 'counter'
        parent::Counter
      when 'map'
        parent::Map
      when 'set'
        parent::Set
      else
        raise CrdtError::UnrecognizedDataType.new dt
      end
    end

    def ==(other)
      return false unless self.class == other.class
      return false unless self.client == other.client
      return equal_bytes?(self.name, other.name)
    end
  end
end
