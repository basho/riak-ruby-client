module Riak
  class Client
    module BeefcakeMessageCodes
      MESSAGE_TO_CODE = {
        :ErrorResp => 0,
        :PingReq => 1,
        :PingResp => 2,
        :GetClientIdReq => 3,
        :GetClientIdResp => 4,
        :SetClientIdReq => 5,
        :SetClientIdResp => 6,
        :GetServerInfoReq => 7,
        :GetServerInfoResp => 8,
        :GetReq => 9,
        :GetResp => 10,
        :PutReq => 11,
        :PutResp => 12,
        :DelReq => 13,
        :DelResp => 14,
        :ListBucketsReq => 15,
        :ListBucketsResp => 16,
        :ListKeysReq => 17,
        :ListKeysResp => 18,
        :GetBucketReq => 19,
        :GetBucketResp => 20,
        :SetBucketReq => 21,
        :SetBucketResp => 22,
        :MapRedReq => 23,
        :MapRedResp => 24,
        :IndexReq => 25,
        :IndexResp => 26,
        :SearchQueryReq => 27,
        :SearchQueryResp => 28,
        :ResetBucketReq => 29,
        :ResetBucketResp => 30,

        # bucket types
        :GetBucketTypeReq => 31,
        :SetBucketTypeReq => 32,
        :ResetBucketTypeReq => 33,

        # riak cs
        :CSBucketReq => 40,
        :CSBucketResp => 41,

        # 1.4 counters
        :CounterUpdateReq => 50,
        :CounterUpdateResp => 51,
        :CounterGetReq => 52,
        :CounterGetResp => 53,

        # yokozuna
        :YokozunaIndexGetReq => 54,
        :YokozunaIndexGetResp => 55,
        :YokozunaIndexPutReq => 56,
        :YokozunaIndexDeleteReq => 57,
        :YokozunaSchemaGetReq => 58,
        :YokozunaSchemaGetResp => 59,
        :YokozunaSchemaPutReq => 60,

        # riak 2 CRDT
        :DtFetchReq => 80,
        :DtFetchResp => 81,
        :DtUpdateReq => 82,
        :DtUpdateResp => 83,

        # internal
        :AuthReq => 253,
        :AuthResp => 254,
        :StartTls => 255
      }

      CODE_TO_MESSAGE = MESSAGE_TO_CODE.invert

      # ugly shims
      def self.index(message_name)
        MESSAGE_TO_CODE[message_name]
      end

      def self.[](message_code)
        CODE_TO_MESSAGE[message_code]
      end
    end
  end
end
