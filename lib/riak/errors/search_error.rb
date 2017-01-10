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
  class SearchError < Error
    class IndexExistsError < SearchError
      def initialize(name)
        super t('search.index_exists', name: name)
      end
    end

    class SchemaExistsError < SearchError
      def initialize(name)
        super t('search.schema_exists', name: name)
      end
    end

    class IndexArgumentError < SearchError
      def initialize(index)
        super t('search.index_argument_error', index: index)
      end
    end

    class IndexNonExistError < SearchError
      def initialize(index)
        super t('search.index_non_exist', index: index)
      end
    end

    class UnexpectedResultError < SearchError
      def initialize(expected, actual)
        super t('search.unexpected_result', expected: expected, actual: actual)
      end
    end
  end
end
