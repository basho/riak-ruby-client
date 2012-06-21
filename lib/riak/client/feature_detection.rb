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
        server_version >= Gem::Version.new("1.1.0")
      end

      # @return [true,false] whether secondary index queries are
      #  supported over Protocol Buffers
      def pb_indexes?
        server_version >= Gem::Version.new("1.2.0")
      end

      # @return [true,false] whether search queries are supported over
      #   Protocol Buffers
      def pb_search?
        server_version >= Gem::Version.new("1.2.0")
      end
    end
  end
end
