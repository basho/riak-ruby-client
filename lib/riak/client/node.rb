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
