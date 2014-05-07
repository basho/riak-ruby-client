require 'riak/errors/base'

module Riak
  class ConnectionError < Error
  end

  class TlsError < ConnectionError
  end

  class UserConfigurationError < ConnectionError
    def initialize
      super t('pbc.user_not_username')
    end
  end
end
