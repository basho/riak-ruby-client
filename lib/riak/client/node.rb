module Riak
  class Client
    class Node
      # Represents a single riak node in a cluster.

      include Util::Translation
      include Util::Escape

      VALID_OPTIONS = [:host, :pb_port]

      # For a score which halves in 10 seconds, choose
      # ln(1/2)/10
      ERRORS_DECAY_RATE = Math.log(0.5)/10

      # What IP address or hostname does this node listen on?
      attr_accessor :host
      # Which port does the protocol buffers interface listen on?
      attr_accessor :pb_port
      attr_accessor :ssl_options
      # A Decaying rate of errors.
      attr_reader :error_rate

      def initialize(client, opts = {})
        @client = client
        @host = opts[:host] || "127.0.0.1"
        @pb_port = opts[:pb_port] || 8087

        @error_rate = Decaying.new
      end

      def ==(o)
        o.kind_of? Node and
          @host == o.host and
          @pb_port == o.pb_port
      end

      # Can this node be used for protocol buffers requests?
      def protobuffs?
        # TODO: Need to sort out capabilities
        true
      end

      def inspect
        "#<Node #{@host}:#{@pb_port}>"
      end
    end
  end
end
