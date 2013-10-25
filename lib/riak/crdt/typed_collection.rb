module Riak
  module Crdt
    class TypedCollection
      def initialize(type, parent, contents={})
        @type = type
        @parent = parent
        @contents = contents.stringify_keys
      end

      def [](key)
        key = key.to_s
        return @contents[key] if @contents.has_key? key
        return @type.new
      end
    end
  end
end
