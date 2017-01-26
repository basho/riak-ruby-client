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
    attr_accessor :disable_list_exceptions

    # backwards compat
    alias :disable_list_keys_warnings :disable_list_exceptions
    alias :disable_list_keys_warnings= :disable_list_exceptions=

    # Set a custom logger object (e.g. Riak.logger = Rails.logger)
    attr_accessor :logger
  end
  self.disable_list_exceptions = false
  self.logger = NullLogger.new
end
