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
  end
end
