module Riak
  class Client
    class BeefcakeProtobuffsBackend
      def crdt_operator
        return CrdtOperator.new self
      end
      
      class CrdtOperator
        include Util::Translation

        attr_reader :backend
        
        def initialize(backend)
          @backend = backend
        end

        def operate(bucket, key, bucket_type, operation, options={})
          serialized = serialize(operation)
          args = {
            bucket: bucket,
            key: key,
            type: bucket_type,
            op: serialized
          }.merge options
          request = DtUpdateReq.new args
          backend.write_protobuff :DtUpdateReq, request

          response = decode
          return response
        end

        def serialize(operations)
          return serialize [operations] unless operations.is_a? Enumerable

          serialize_wrap operations
        end

        private

        def decode
          header = socket.read 5

          if header.nil?
            backend.teardown
            raise SocketError, t('pbc.unexpected_eof')
          end

          msglen, msgcode = header.unpack 'NC'

          if BeefcakeProtobuffsBackend::MESSAGE_CODES[msgcode] == :ErrorResp
            error = socket.read(msglen - 1)
            resp = RpbErrorResp.decode error
            raise ProtobuffsFailedRequest.new resp.errcode, resp.errmsg
          elsif BeefcakeProtobuffsBackend::MESSAGE_CODES[msgcode] != :DtUpdateResp
            backend.teardown
            raise SocketError, t('pbc.wanted_dt_update_resp')
          end

          message = socket.read(msglen - 1)

          DtUpdateResp.decode message
        end

        def socket
          backend.socket
        end

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
          operations.map do |operation|
            inner_serialize operation.value
          end
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

          MapOp.new(
                    updates: inner_serialized
                    )
        end

        def serialize_inner_map(map_op)
          inner_op = map_op.value
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
      end
    end
  end
end
