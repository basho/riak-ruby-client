module Riak
  module Crdt
    class Register < String
      def self.update_operation_name
        :register_op
      end

      def self.map_field_type
        Crdt::Base.backend_class::MapField::MapFieldType::REGISTER
      end
    end
  end
end
