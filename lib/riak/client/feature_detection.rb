module Riak
  class Client
    # Methods that can be used to determine whether certain features
    # are supported by the Riak node to which the client backend is
    # connected.
    #
    # Backends must implement the "get_server_version" method,
    # returning a string representing the Riak node's version. This is
    # implemented on HTTP using the stats resource, and on Protocol
    # Buffers using the RpbGetServerInfoReq message.
    module FeatureDetection
      # Constants representing Riak versions
      VERSION = {
        1 => Gem::Version.new("1.0.0"),
        1.1 => Gem::Version.new("1.1.0"),
        1.2 => Gem::Version.new("1.2.0")
      }.freeze

      # @return [String] the version of the Riak node
      # @abstract
      def get_server_version
        raise NotImplementedError
      end

      # @return [Gem::Version] the version of the Riak node to which
      #   this backend is connected
      def server_version
        @server_version ||= Gem::Version.new(get_server_version)
      end

      # @return [true,false] whether MapReduce requests can be submitted without
      #   phases.
      def mapred_phaseless?
        at_least? VERSION[1.1]
      end

      # @return [true,false] whether secondary index queries are
      #  supported over Protocol Buffers
      def pb_indexes?
        at_least? VERSION[1.2]
      end

      # @return [true,false] whether search queries are supported over
      #   Protocol Buffers
      def pb_search?
        at_least? VERSION[1.2]
      end

      # @return [true,false] whether conditional fetch/store semantics
      #   are supported over Protocol Buffers
      def pb_conditionals?
        at_least? VERSION[1]
      end

      # @return [true,false] whether additional quorums and FSM
      #   controls are available, e.g. primary quorums, basic_quorum,
      #   notfound_ok
      def quorum_controls?
        at_least? VERSION[1]
      end

      # @return [true,false] whether "not found" responses might
      #   include vclocks
      def tombstone_vclocks?
        at_least? VERSION[1]
      end

      # @return [true,false] whether partial-fetches (vclock and
      #   metadata only) are supported over Protocol Buffers
      def pb_head?
        at_least? VERSION[1]
      end

      protected
      # @return [true,false] whether the server version is the same or
      #  newer than the requested version
      def at_least?(version)
        server_version >= version
      end

      # Backends should call this when their connection is interrupted
      # or reset so as to facilitate rolling upgrades
      def reset_server_version
        @server_version = nil
      end
    end
  end
end
