module Riak
  class Client
    class BeefcakeProtobuffsBackend
      class CrdtOperator
        def serialize(operation)
          case operation.type
          when :counter
            return serialize_counter operation
          end
        end

        private
        
        def serialize_counter(counter_op)
          DtOp.new(
                   counter_op: CounterOp.new(
                                             increment: counter_op.value
                                             )
                   )
        end
      end
    end
  end
end
