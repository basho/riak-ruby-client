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
  class ConnectionError < Error
  end

  class TlsError < ConnectionError
    class SslVersionConfigurationError < TlsError
      def initialize
        super t('ssl.version_configuration_error')
      end
    end

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
