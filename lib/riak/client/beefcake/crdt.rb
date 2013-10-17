module Riak
  class Client
    class BeefcakeProtobuffsBackend
      def fetch_crdt(bucket, key, type, options={})
        bucket = bucket.name if bucket.is_a? Bucket
        args = options.merge(
                             bucket: bucket,
                             key: key,
                             type: type
                             )

        message = DtFetchReq.new(args)
        pp message
        
        write_protobuff(:DtFetchReq, message)
        decode_response
      end

      def store_counter(bucket, key, type, options={})
        bucket = bucket.name if bucket.is_a? Bucket
        operation = DtOp.new counter_op: CounterOp.new
        args = options.merge(
                             bucket: bucket,
                             key: key,
                             type: type,
                             op: operation
                             )

        message = DtUpdateReq.new args
        pp message
        write_protobuff :DtUpdateReq, message
        decode_response
      end
    end
  end
end
