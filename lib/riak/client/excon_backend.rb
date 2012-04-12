require 'riak/failed_request'
require 'riak/client/http_backend'
require 'riak/client/http_backend/request_headers'

module Riak
  class Client
    # An HTTP backend for Riak::Client that uses Wesley Beary's Excon
    # HTTP library. Conforms to the Riak::Client::HTTPBackend
    # interface.
    class ExconBackend < HTTPBackend
      def self.configured?
        begin
          require 'excon'
          Client::NETWORK_ERRORS << Excon::Errors::SocketError
          Client::NETWORK_ERRORS << Excon::Errors::TimeoutError if defined? Excon::Errors::TimeoutError
          Client::NETWORK_ERRORS.uniq!
          minimum_version?("0.5.7") && handle_deprecations && patch_excon
        rescue LoadError
          false
        end
      end

      # Adjusts Excon's connection collection to allow multiple
      # connections to the same host from the same Thread. Instead we
      # use the Riak::Client::Pool to segregate connections.
      # @note This can be changed when Excon has a proper pool of its own.
      def self.patch_excon
        unless defined? @@patched
          ::Excon::Connection.class_eval do
            def sockets
              @sockets ||= {}
            end
          end
        end
        @@patched = true
      end

      # Defines instance methods that handle changes in the Excon API
      # across different versions.
      def self.handle_deprecations
        # Define #make_request
        if minimum_version?("0.10.2")
          def make_request(params, block)
            params[:response_block] = block if block
            connection.request(params)
          end
        else
          def make_request(params, block)
            response = connection.request(params, &block)
          end
        end

        # Define #configure_ssl
        if minimum_version?("0.9.6")
          def configure_ssl
            Excon.defaults[:ssl_verify_peer] = (@node.ssl_options[:verify_mode].to_s === "peer")
            Excon.defaults[:ssl_ca_path]     = @node.ssl_options[:ca_path] if @node.ssl_options[:ca_path]
          end
        else
          def configure_ssl
            Excon.ssl_verify_peer = (@node.ssl_options[:verify_mode].to_s === "peer")
            Excon.ssl_ca_path     = @node.ssl_options[:ca_path] if @node.ssl_options[:ca_path]
          end
        end
        private :make_request, :configure_ssl
      end

      # Returns true if the Excon library is at least the given
      # version. This is used inside the backend to check how to
      # provide certain request and configuration options.
      def self.minimum_version?(version)
        Gem::Version.new(Excon::VERSION) >= Gem::Version.new(version)
      end

      def teardown
        connection.reset
      end

      private
      def perform(method, uri, headers, expect, data=nil, &block)
        configure_ssl if @node.ssl_enabled?

        params = {
          :method => method.to_s.upcase,
          :headers => RequestHeaders.new(headers).to_hash,
          :path => uri.path
        }
        params[:query] = uri.query if uri.query
        params[:body] = data if [:put,:post].include?(method)
        params[:idempotent] = (method != :post)

        # Later versions of Excon pass multiple arguments to the block
        block = lambda {|*args| yield args.first } if block_given?

        response = make_request(params, block)
        response_headers.initialize_http_header(response.headers)

        if valid_response?(expect, response.status)
          result = {:headers => response_headers.to_hash, :code => response.status}
          if return_body?(method, response.status, block_given?)
            result[:body] = response.body
          end
          result
        else
          raise HTTPFailedRequest.new(method, expect, response.status, response_headers.to_hash, response.body)
        end
      end

      def connection
        @connection ||= Excon::Connection.new(root_uri.to_s)
      end
    end
  end
end
