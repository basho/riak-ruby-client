require 'riak'
require 'socket'
require 'base64'
require 'digest/sha1'
require 'riak/util/translation'
require 'riak/client/feature_detection'
require 'riak/client/beefcake/message_codes'

module Riak
  class Client
    class ProtobuffsBackend
      include Util::Translation
      include Util::Escape
      include FeatureDetection

      MESSAGE_CODES = BeefcakeMessageCodes

      def self.simple(method, code)
        define_method method do
          socket.write([1, MESSAGE_CODES.index(code)].pack('NC'))
          decode_response
        end
      end

      attr_accessor :client
      attr_accessor :node
      def initialize(client, node)
        @client = client
        @node = node
      end

      # Performs a secondary-index query via emulation through MapReduce.
      # @param [String, Bucket] bucket the bucket to query
      # @param [String] index the index to query
      # @param [String, Integer, Range] query the equality query or
      #   range query to perform
      # @return [Array<String>] a list of keys matching the query
      def get_index(bucket, index, query)
        mr = Riak::MapReduce.new(client).index(bucket, index, query)
        unless mapred_phaseless?
          mr.reduce(%w[riak_kv_mapreduce reduce_identity], :arg => {:reduce_phase_only_1 => true}, :keep => true)
        end
        mapred(mr).map {|p| p.last }
      end

      # Performs search query via emulation through MapReduce. This
      # has more limited capabilites than native queries. Essentially,
      # only the 'id' field of matched documents will ever be
      # returned, the 'fl' and other options have no effect.
      # @param [String] index the index to query
      # @param [String] query the Lucene-style search query
      # @param [Hash] options ignored in MapReduce emulation
      # @return [Hash] the search results
      def search(index, query, options={})
        mr = Riak::MapReduce.new(client).search(index || 'search', query)
        unless mapred_phaseless?
          mr.reduce(%w[riak_kv_mapreduce reduce_identity], :arg => {:reduce_phase_only_1 => true}, :keep => true)
        end
        docs = mapred(mr).map {|d| {'id' => d[1] } }
        # Since we don't get this information back from the MapReduce,
        # we have to fake the max_score and num_found.
        { 'docs' => docs,
          'num_found' => docs.size,
          'max_score' => 0.0 }
      end

      # Gracefully shuts down this connection.
      def teardown
        reset_socket
      end
      
      def socket
        @socket ||= new_socket
      end

      private
      def get_server_version
        server_info[:server_version]
      end

      # Implemented by subclasses
      def decode_response
        raise NotImplementedError
      end
      
      def new_socket
        raise NotImplementedError
      end

      def reset_socket
        reset_server_version
        @socket.close if @socket && !@socket.closed?
        @socket = nil
      end

      UINTMAX = 0xffffffff
      QUORUMS = {
        "one" => UINTMAX - 1,
        "quorum" => UINTMAX - 2,
        "all" => UINTMAX - 3,
        "default" => UINTMAX - 4
      }.freeze

      def prune_unsupported_options(req,options={})
        unless quorum_controls?
          [:notfound_ok, :basic_quorum, :pr, :pw].each {|k| options.delete k }
        end
        unless key_object_bucket_timeouts?
          options.delete :timeout
        end
        unless pb_head?
          [:head, :return_head].each {|k| options.delete k }
        end
        unless tombstone_vclocks?
          options.delete :deletedvclock
          options.delete :vclock if req == :DelReq
        end
        unless pb_conditionals?
          [:if_not_modified, :if_none_match, :if_modified].each {|k| options.delete k }
        end
        options
      end

      def normalize_quorums(options={})
        options.dup.tap do |o|
          [:r, :pr, :w, :pw, :dw, :rw].each do |k|
            next o[k] = normalize_quorum_value(o[k]) if o[k]
            s = k.to_s
            o[k] = o[s] = denormalize_quorum_value(o[s]) if o[s]
          end
        end
      end

      def normalize_quorum_value(q)
        QUORUMS[q.to_s] || q.to_i
      end

      def denormalize_quorum_value(q)
        QUORUMS.invert[q] || q.to_i
      end
    end
  end
end
