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

require 'riak/errors/base'

module Riak
  class FailedRequest < Error
    def initialize(message)
      super(message ||  t('failed_request'))
    end
  end

  # Exception raised when receiving an unexpected Protocol Buffers response from Riak
  class ProtobuffsFailedRequest < FailedRequest
    attr_reader :code, :original_message
    def initialize(code, message)
      super t('protobuffs_failed_request', :code => code, :body => message)
      @original_message = message
      @code = code
      @not_found = code == :not_found
      @server_error = code == :server_error
    end

    # @return [true, false] whether the error response is in JSON
    def is_json?
      begin
        JSON.parse(@original_message)
        true
      rescue
        false
      end
    end

    # @return [true,false] whether the error represents a "not found" response
    def not_found?
      @not_found
    end

    # @return [true,false] whether the error represents an internal
    #   server error
    def server_error?
      @server_error
    end

    def body
      @original_message
    end
  end

  class ProtobuffsUnexpectedResponse < ProtobuffsFailedRequest
    def initialize(code, expected)
      super code, t('pbc.unexpected_response', expected: expected, actual: code)
    end
  end

  class ProtobuffsErrorResponse < ProtobuffsFailedRequest
    def initialize(payload)
      super payload.errcode, payload.errmsg
    end
  end
end
