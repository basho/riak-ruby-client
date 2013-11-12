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

      def []=(key, value)
        update_op = backend_class::MapUpdate.new
        update_op.field = key.to_s
        update_op[@type.update_operation_name] = value

        parent_operation = backend_class::MapOp.new updates: [update_op]
        @parent.update parent_operation
      end

      def delete(key)
        delete_op = backend_class::MapField.new
        delete_op.name = key
        delete_op.type = @type.map_field_type

        parent_operation = backend_class::MapOp.new removes: [delete_op]
        @parent.update parent_operation
      end
      
      private
      def backend_class
        @parent.backend_class
      end
    end
  end
end
