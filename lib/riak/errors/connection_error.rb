require 'riak/errors/base'

module Riak
  class ConnectionError < Error
  end

  class TlsError < ConnectionError
    class CertHostMismatchError < TlsError
      def initialize
        super t('ssl.cert_host_mismatch')
      end
    end

    class CertNotValidError < TlsError
      def initialize
        super t('ssl.cert_not_valid')
      end
    end

    class CertRevokedError < TlsError
      def initialize
        super t('ssl.cert_revoked')
      end
    end

    class ReadDataError < TlsError
      def initialize(actual, candidate)
        super t('ssl.read_data_error', actual: actual, candidate: candidate)
      end
    end

    class UnknownKeyTypeError < TlsError
      def initialize
        super t('ssl.unknown_key_type')
      end
    end
  end

  class UserConfigurationError < ConnectionError
    def initialize
      super t('pbc.user_not_username')
    end
  end
end
