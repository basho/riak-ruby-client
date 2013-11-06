module Riak
  module Crdt
    class Register < String
      def self.update_operation_name
        :register_op
      end
    end
  end
end
