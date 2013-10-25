module Riak
  module Crdt
    class TypedCollection
      def initialize(type, contents={})
        @type = type
        @contents = contents
      end
    end
  end
end
