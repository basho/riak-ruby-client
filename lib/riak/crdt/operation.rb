module Riak
  module Crdt
    # @api private
    module Operation
      class Update
        attr_accessor :parent
        attr_accessor :name
        attr_accessor :type
        attr_accessor :value
      end

      class Delete
        attr_accessor :parent
        attr_accessor :name
        attr_accessor :type
      end
    end
  end
end
