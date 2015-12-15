require 'riak/encoding'
require 'riak/core_ext'
require 'riak/client'
require 'riak/map_reduce'
require 'riak/util/translation'
require 'riak/crdt'
require 'riak/instrumentation'

# The Riak module contains all aspects of the client interface to
# Riak.
module Riak
  # Utility classes and mixins
  module Util; end
  extend Util::Translation

  class NullLogger
    def fatal(msg) end

    def error(msg) end

    def warn(msg)  end

    def info(msg)  end

    def debug(msg) end
  end

  class << self
    # Only change this if you really know what you're doing. Better to
    # err on the side of caution and assume you don't.
    # @private
    attr_accessor :disable_list_keys_warnings

    # Set a custom logger object (e.g. Riak.logger = Rails.logger)
    attr_accessor :logger
  end
  self.disable_list_keys_warnings = false
  self.logger = NullLogger.new
end
