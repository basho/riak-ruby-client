module Riak
  module Crdt
    class TypedCollection

      NEEDS_NAME = ::Set.new [InnerCounter, InnerSet]
      
      def initialize(type, parent, contents={})
        @type = type
        @parent = parent
        contents = {} if contents.nil?
        stringified_contents = contents.stringify_keys
        @contents = stringified_contents.keys.inject(Hash.new) do |contents, key|
          contents.tap do |c|
            c[key] = @type.new self, stringified_contents[key]
            if NEEDS_NAME.include? @type
              c[key].name = key
            end
          end
        end
      end

      def include?(key)
        @contents.include? normalize_key(key)
      end
      
      def [](key)
        key = normalize_key key
        return @contents[key] if include? key

        new_instance = @type.new self
        if NEEDS_NAME.include? @type
          new_instance.name = key
        end

        return new_instance
      end

      def []=(key, value)
        key = normalize_key key

        operation = @type.update value
        operation.name = key

        @parent.operate operation
      end
      alias :increment :[]=

      def delete(key)
        key = normalize_key key
        operation = @type.delete
        operation.name = key

        @parent.operate operation
      end

      def operate(key, inner_operation)
        key = normalize_key key
        
        inner_operation.name = key
        
        @parent.operate inner_operation
      end
      
      private
      def normalize_key(unnormalized_key)
        unnormalized_key.to_s
      end
    end
  end
end
