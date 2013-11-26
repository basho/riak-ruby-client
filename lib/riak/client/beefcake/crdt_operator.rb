module Riak
  class Client
    class BeefcakeProtobuffsBackend
      class CrdtOperator
        def serialize(operation)
          case operation.type
          when :counter
            return serialize_counter operation
          when :set
            return serialize_set operation
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

        def serialize_set(set_op)
          value = set_op.value or nil
          
          DtOp.new(
                   set_op: SetOp.new(
                                     adds: value[:add],
                                     removes: value[:remove]
                                     )
                   )
        end
      end
    end
  end
end
