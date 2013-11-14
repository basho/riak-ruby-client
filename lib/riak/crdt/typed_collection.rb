module Riak
  module Crdt
    class TypedCollection
      def initialize(type, parent, contents={})
        @type = type
        @parent = parent
        stringified_contents = contents.stringify_keys
        @contents = stringified_contents.keys.inject(Hash.new) do |contents, key|
          contents.tap do |c|
            c[key] = @type.new self, stringified_contents[key]
          end
        end
      end

      def include?(key)
        @contents.include? normalize_key(key)
      end
      
      def [](key)
        key = normalize_key key
        return @contents[key] if include? key
        return @type.new
      end

      def []=(key, value)
        key = normalize_key key

        operation = @contents[key].update value
        operation.name = key

        @parent.operate operation
      end
      
      private
      def normalize_key(unnormalized_key)
        unnormalized_key.to_s
      end
    end
  end
end
