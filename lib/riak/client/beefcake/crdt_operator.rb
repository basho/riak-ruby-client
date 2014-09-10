require 'riak/errors/crdt_error'

module Riak
  class Client
    class BeefcakeProtobuffsBackend

      # Returns a new {CrdtOperator} for serializing CRDT operations into 
      # protobuffs and sending them to a Riak cluster.
      # @api private
      def crdt_operator
        return CrdtOperator.new self
      end
      
      # Serializes and writes CRDT operations from {Riak::Crdt::Operation} members
      # into protobuffs, and writes them to a Riak cluster.
      # @api private
      class CrdtOperator
        include Util::Translation

        attr_reader :backend
        
        def initialize(backend)
          @backend = backend
        end

        # Serializes and writes CRDT operations.
        def operate(bucket, key, bucket_type, operation, options={})
          serialized = serialize(operation)
          args = {
            bucket: bucket,
            key: key,
            type: bucket_type,
            op: serialized,
            return_body: true,
          }.merge options
          request = DtUpdateReq.new args
          begin
            return backend.protocol do |p|
              p.write :DtUpdateReq, request
              p.expect :DtUpdateResp, DtUpdateResp, empty_body_acceptable: true
            end
          rescue ProtobuffsErrorResponse => e
            raise unless e.message =~ /precondition/
            raise CrdtError::PreconditionError.new e.message
          end
        end

        # Serializes CRDT operations without writing them.
        def serialize(operations)
          return serialize [operations] unless operations.is_a? Enumerable

          serialize_wrap operations
        end

        private
        def serialize_wrap(operations)
          raise ArgumentError, t('crdt.serialize_no_ops') if operations.empty?
          ops = serialize_group operations

          DtOp.new(wrap_field_for(operations) => ops)
        end

        def wrap_field_for(ops)
          "#{ops.first.type.to_s}_op".to_sym
        end
        
        def serialize_group(operations)
          case operations.first.type
          when :counter
            serialize_counter operations
          when :set
            serialize_set operations
          when :map
            serialize_map operations
          else
            raise ArgumentError, t('crdt.unknown_field', symbol: operation.type.inspect)
          end
        end
        
        def inner_serialize_group(operations)
          updates, deletes = operations.partition do |op| 
            op.value.is_a? Riak::Crdt::Operation::Update
          end
          serialized_updates = updates.map do |operation|
            inner_serialize operation.value
          end
          serialized_deletes = deletes.map do |operation|
            inner_serialize_delete operation.value
          end

          { updates: serialized_updates,
            removes: serialized_deletes
          }
        end

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
            raise ArgumentError, t('crdt.unknown_inner_field',
                                   symbol: operation.type.inspect)
          end
        end

        def inner_serialize_delete(operation)
          MapField.new(
                       name: operation.name,
                       type: type_symbol_to_type_enum(operation.type)
                       )
        end
        
        def serialize_counter(counter_ops)
          amount = counter_ops.inject(0){|m, o| m += o.value }
          CounterOp.new(increment: amount)
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
          operation_value = flag_op.value ? MapUpdate::FlagOp::ENABLE : MapUpdate::FlagOp::DISABLE
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

        def serialize_set(set_ops)
          adds = ::Set.new
          removes = ::Set.new
          set_ops.each do |o|
            adds.add [o.value[:add]] if o.value[:add]
            removes.merge [o.value[:remove]] if o.value[:remove]
          end
          
          SetOp.new(
                    adds: adds.to_a.flatten,
                    removes: removes.to_a.flatten
                    )
        end

        def serialize_inner_set(set_op)
          value = set_op.value or nil

          MapUpdate.new(
                        field: MapField.new(
                                            name: set_op.name,
                                            type: MapField::MapFieldType::SET
                                            ),
                        set_op: SetOp.new(
                                          adds: value[:add],
                                          removes: value[:remove]
                                          )
                        )
        end

        def serialize_map(map_ops)
          inner_serialized = inner_serialize_group map_ops

          MapOp.new(inner_serialized)
        end

        def serialize_inner_map(map_op)
          inner_op = map_op.value
          if inner_op.is_a? Riak::Crdt::Operation::Delete
            return MapUpdate.new(field: MapField.new(
                                                     name: map_op.name,
                                                     type: MapField::MapFieldType::MAP
                                                     ),
                                 map_op: MapOp.new(
                                                   removes: inner_op.name)
                                 )
          end
          inner_serialized = inner_serialize inner_op

          MapUpdate.new(
                        field: MapField.new(
                                            name: map_op.name,
                                            type: MapField::MapFieldType::MAP
                                            ),
                        map_op: MapOp.new(
                                          updates: [inner_serialized]
                                     ))
        end

        def type_symbol_to_type_enum(sym)
          MapField::MapFieldType.const_get sym.to_s.upcase
        end
      end
    end
  end
end
