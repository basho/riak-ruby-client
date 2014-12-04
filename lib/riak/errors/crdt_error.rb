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

    class UnrecognizedDataType
      def initialize(given_type)
        super t('crdt.unrecognized_type', type: given_type)
      end
    end
  end
end
