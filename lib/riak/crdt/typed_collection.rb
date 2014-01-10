module Riak
  module Crdt
    class TypedCollection

      ALREADY_WRAPPED = ::Set.new [InnerCounter, InnerFlag, InnerMap]
      NEEDS_NAME = ::Set.new [InnerCounter, InnerSet, InnerMap]
      INITIALIZE_NIL = ::Set.new [InnerRegister]
      
      def initialize(type, parent, contents={})
        @type = type
        @parent = parent
        contents = {} if contents.nil?
        stringified_contents = contents.stringify_keys
        @contents = stringified_contents.keys.inject(Hash.new) do |contents, key|
          contents.tap do |c|
            content = stringified_contents[key]
            if ALREADY_WRAPPED.include? content.class
              c[key] = content
            else
              c[key] = @type.new self, content
            end
            c[key].name = key if needs_name?
          end
        end
      end

      def reparent(new_parent)
        reparented = self.class.new(@type,
                                    new_parent,
                                    @contents)
      end
      
      def include?(key)
        @contents.include? normalize_key(key)
      end
      
      def [](key)
        key = normalize_key key
        return @contents[key] if include? key

        return nil if initialize_nil?
        
        new_instance = @type.new self
        new_instance.name = key if needs_name?

        return new_instance
      end

      def []=(key, value)
        key = normalize_key key

        operation = @type.update value
        operation.name = key

        result = @parent.operate operation

        @contents[key] = @type.new self, value
        @contents[key].name = key if needs_name?
        
        result
      end
      alias :increment :[]=

      def delete(key)
        key = normalize_key key
        operation = @type.delete
        operation.name = key

        @parent.operate operation

        @contents.delete key
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

      def initialize_nil?
        INITIALIZE_NIL.include? @type
      end
      
      def needs_name?
        NEEDS_NAME.include? @type
      end
    end
  end
end
