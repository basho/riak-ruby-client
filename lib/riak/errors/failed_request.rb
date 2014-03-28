require 'riak/errors/base'

module Riak
  class FailedRequest < Error
    def initialize(message)
      super(message ||  t('failed_request'))
    end
  end

  # Exception raised when receiving an unexpected Protocol Buffers response from Riak
  class ProtobuffsFailedRequest < FailedRequest
    def initialize(code, message)
      super t('protobuffs_failed_request', :code => code, :body => message)
      @original_message = message
      @not_found = code == :not_found
      @server_error = code == :server_error
    end

    # @return [true, false] whether the error response is in JSON
    def is_json?
      begin
        JSON.parse(original_message)
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
