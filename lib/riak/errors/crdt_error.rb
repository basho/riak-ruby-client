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
  class CrdtError < Error

    class SetRemovalWithoutContextError < CrdtError
      def initialize
        super t('crdt.set_removal_without_context')
      end
    end

    class PreconditionError < CrdtError
      def initialize(message)
        super t('crdt.precondition', message: message)
      end
    end

    class UnrecognizedDataType < CrdtError
      def initialize(given_type)
        super t('crdt.unrecognized_type', type: given_type)
      end
    end

    class UnexpectedDataType < CrdtError
      def initialize(given_type, expected_type)
        super t('crdt.unexpected_type',
                given: given_type,
                expected: expected_type)
      end
    end

    class NotACrdt < CrdtError
      def initialize
        super t('crdt.not_a_crdt')
      end
    end
  end
end
