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
  end
end
