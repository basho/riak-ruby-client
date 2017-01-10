# Copyright 2010-present Basho Technologies, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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

        # preflist
        :GetBucketKeyPreflistReq => 33,
        :GetBucketKeyPreflistResp => 34,

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

        # riak time series
        :TsQueryReq => 90,
        :TsQueryResp => 91,
        :TsPutReq => 92,
        :TsPutResp => 93,
        :TsDelReq => 94,
        :TsDelResp => 95,
        :TsGetReq => 96,
        :TsGetResp => 97,
        :TsListKeysReq => 98,
        :TsListKeysResp => 99,

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
