module Riak
  class Client
    class BeefcakeProtobuffsBackend
      class CrdtOperator
        include Util::Translation
        def serialize(operation)
          case operation.type
          when :counter
            serialize_counter operation
          when :set
            serialize_set operation
          when :map
            serialize_map operation
          else
            raise ArgumentError, t('crdt.unknown_field', symbol: operation.type.inspect)
          end
        end

        private

        def inner_serialize(operation)
          case operation.type
          when :counter
            serialize_inner_counter operation
          when :flag
            serialize_flag operation
          when :register
            serialize_register operation
          when :set
            serialize_inner_set operation
          when :map
            serialize_inner_map operation
          else
            raise ArgumentError, t('crdt.unknown_inner_field', symbol: operation.type.inspect)
          end
        end
        
        def serialize_counter(counter_op)
          DtOp.new(
                   counter_op: CounterOp.new(
                                             increment: counter_op.value
                                             )
                   )
        end

        def serialize_inner_counter(counter_op)
          MapUpdate.new(
                        field: MapField.new(
                                            name: counter_op.name,
                                            type: MapField::MapFieldType::COUNTER
                                            ),
                        counter_op: CounterOp.new(
                                                  increment: counter_op.value
                                                  )
                        )
        end

        def serialize_flag(flag_op)
          operation_value = flag_op ? MapUpdate::FlagOp::ENABLE : MapUpdate::FlagOp::DISABLE
          MapUpdate.new(
                        field: MapField.new(
                                            name: flag_op.name,
                                            type: MapField::MapFieldType::FLAG
                                            ),
                        flag_op: operation_value
                        )
        end

        def serialize_register(register_op)
          MapUpdate.new(
                        field: MapField.new(
                                            name: register_op.name,
                                            type: MapField::MapFieldType::REGISTER
                                            ),
                        register_op: register_op.value
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

        def serialize_map(map_op)
          inner_op = map_op.value
          inner_serialized = inner_serialize inner_op

          DtOp.new(
                   map_op: MapOp.new(
                                     updates: [inner_serialized]
                                     )
                   )
        end
      end
    end
  end
end
