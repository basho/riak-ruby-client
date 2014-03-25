require 'riak/errors/base'

module Riak
  class ConnectionError < Error
  end

  class TlsError < ConnectionError
  end
end
