require 'beefcake'

module Riak
  class Client
    # @private
    class BeefcakeProtobuffsBackend
## Generated from riak.proto for 
require "beefcake"


class RpbErrorResp
  include Beefcake::Message
end


class RpbGetServerInfoResp
  include Beefcake::Message
end


class RpbPair
  include Beefcake::Message
end


class RpbGetBucketReq
  include Beefcake::Message
end


class RpbGetBucketResp
  include Beefcake::Message
end


class RpbSetBucketReq
  include Beefcake::Message
end


class RpbResetBucketReq
  include Beefcake::Message
end


class RpbModFun
  include Beefcake::Message
end


class RpbCommitHook
  include Beefcake::Message
end


class RpbBucketProps
  include Beefcake::Message
end


class RpbErrorResp
  required :errmsg, :bytes, 1
  required :errcode, :uint32, 2
end

class RpbGetServerInfoResp
  optional :node, :bytes, 1
  optional :server_version, :bytes, 2
end

class RpbPair
  required :key, :bytes, 1
  optional :value, :bytes, 2
end

class RpbGetBucketReq
  required :bucket, :bytes, 1
end

class RpbGetBucketResp
  required :props, RpbBucketProps, 1
end

class RpbSetBucketReq
  required :bucket, :bytes, 1
  required :props, RpbBucketProps, 2
end

class RpbResetBucketReq
  required :bucket, :bytes, 1
end

class RpbModFun
  required :module, :bytes, 1
  required :function, :bytes, 2
end

class RpbCommitHook
  optional :modfun, RpbModFun, 1
  optional :name, :bytes, 2
end

class RpbBucketProps
  module RpbReplMode
    FALSE = 0
    REALTIME = 1
    FULLSYNC = 2
    TRUE = 3
  end
  optional :n_val, :uint32, 1
  optional :allow_mult, :bool, 2
  optional :last_write_wins, :bool, 3
  repeated :precommit, RpbCommitHook, 4
  optional :has_precommit, :bool, 5, :default => false
  repeated :postcommit, RpbCommitHook, 6
  optional :has_postcommit, :bool, 7, :default => false
  optional :chash_keyfun, RpbModFun, 8
  optional :linkfun, RpbModFun, 9
  optional :old_vclock, :uint32, 10
  optional :young_vclock, :uint32, 11
  optional :big_vclock, :uint32, 12
  optional :small_vclock, :uint32, 13
  optional :pr, :uint32, 14
  optional :r, :uint32, 15
  optional :w, :uint32, 16
  optional :pw, :uint32, 17
  optional :dw, :uint32, 18
  optional :rw, :uint32, 19
  optional :basic_quorum, :bool, 20
  optional :notfound_ok, :bool, 21
  optional :backend, :bytes, 22
  optional :search, :bool, 23
  optional :repl, RpbBucketProps::RpbReplMode, 24
  optional :yz_index, :bytes, 25
end
## Generated from riak_kv.proto for 
require "beefcake"


class RpbGetClientIdResp
  include Beefcake::Message
end


class RpbSetClientIdReq
  include Beefcake::Message
end


class RpbGetReq
  include Beefcake::Message
end


class RpbGetResp
  include Beefcake::Message
end


class RpbPutReq
  include Beefcake::Message
end


class RpbPutResp
  include Beefcake::Message
end


class RpbDelReq
  include Beefcake::Message
end


class RpbListBucketsReq
  include Beefcake::Message
end


class RpbListBucketsResp
  include Beefcake::Message
end


class RpbListKeysReq
  include Beefcake::Message
end


class RpbListKeysResp
  include Beefcake::Message
end


class RpbMapRedReq
  include Beefcake::Message
end


class RpbMapRedResp
  include Beefcake::Message
end


class RpbIndexReq
  include Beefcake::Message
end


class RpbIndexResp
  include Beefcake::Message
end


class RpbCSBucketReq
  include Beefcake::Message
end


class RpbCSBucketResp
  include Beefcake::Message
end


class RpbIndexObject
  include Beefcake::Message
end


class RpbContent
  include Beefcake::Message
end


class RpbLink
  include Beefcake::Message
end


class RpbCounterUpdateReq
  include Beefcake::Message
end


class RpbCounterUpdateResp
  include Beefcake::Message
end


class RpbCounterGetReq
  include Beefcake::Message
end


class RpbCounterGetResp
  include Beefcake::Message
end


class RpbGetClientIdResp
  required :client_id, :bytes, 1
end

class RpbSetClientIdReq
  required :client_id, :bytes, 1
end

class RpbGetReq
  required :bucket, :bytes, 1
  required :key, :bytes, 2
  optional :r, :uint32, 3
  optional :pr, :uint32, 4
  optional :basic_quorum, :bool, 5
  optional :notfound_ok, :bool, 6
  optional :if_modified, :bytes, 7
  optional :head, :bool, 8
  optional :deletedvclock, :bool, 9
  optional :timeout, :uint32, 10
  optional :sloppy_quorum, :bool, 11
  optional :n_val, :uint32, 12
end

class RpbGetResp
  repeated :content, RpbContent, 1
  optional :vclock, :bytes, 2
  optional :unchanged, :bool, 3
end

class RpbPutReq
  required :bucket, :bytes, 1
  optional :key, :bytes, 2
  optional :vclock, :bytes, 3
  required :content, RpbContent, 4
  optional :w, :uint32, 5
  optional :dw, :uint32, 6
  optional :return_body, :bool, 7
  optional :pw, :uint32, 8
  optional :if_not_modified, :bool, 9
  optional :if_none_match, :bool, 10
  optional :return_head, :bool, 11
  optional :timeout, :uint32, 12
  optional :asis, :bool, 13
  optional :sloppy_quorum, :bool, 14
  optional :n_val, :uint32, 15
end

class RpbPutResp
  repeated :content, RpbContent, 1
  optional :vclock, :bytes, 2
  optional :key, :bytes, 3
end

class RpbDelReq
  required :bucket, :bytes, 1
  required :key, :bytes, 2
  optional :rw, :uint32, 3
  optional :vclock, :bytes, 4
  optional :r, :uint32, 5
  optional :w, :uint32, 6
  optional :pr, :uint32, 7
  optional :pw, :uint32, 8
  optional :dw, :uint32, 9
  optional :timeout, :uint32, 10
  optional :sloppy_quorum, :bool, 11
  optional :n_val, :uint32, 12
end

class RpbListBucketsReq
  optional :timeout, :uint32, 1
  optional :stream, :bool, 2
end

class RpbListBucketsResp
  repeated :buckets, :bytes, 1
  optional :done, :bool, 2
end

class RpbListKeysReq
  required :bucket, :bytes, 1
  optional :timeout, :uint32, 2
end

class RpbListKeysResp
  repeated :keys, :bytes, 1
  optional :done, :bool, 2
end

class RpbMapRedReq
  required :request, :bytes, 1
  required :content_type, :bytes, 2
end

class RpbMapRedResp
  optional :phase, :uint32, 1
  optional :response, :bytes, 2
  optional :done, :bool, 3
end

class RpbIndexReq
  module IndexQueryType
    eq = 0
    range = 1
  end
  required :bucket, :bytes, 1
  required :index, :bytes, 2
  required :qtype, RpbIndexReq::IndexQueryType, 3
  optional :key, :bytes, 4
  optional :range_min, :bytes, 5
  optional :range_max, :bytes, 6
  optional :return_terms, :bool, 7
  optional :stream, :bool, 8
  optional :max_results, :uint32, 9
  optional :continuation, :bytes, 10
  optional :timeout, :uint32, 11
end

class RpbIndexResp
  repeated :keys, :bytes, 1
  repeated :results, RpbPair, 2
  optional :continuation, :bytes, 3
  optional :done, :bool, 4
end

class RpbCSBucketReq
  required :bucket, :bytes, 1
  required :start_key, :bytes, 2
  optional :end_key, :bytes, 3
  optional :start_incl, :bool, 4, :default => true
  optional :end_incl, :bool, 5, :default => false
  optional :continuation, :bytes, 6
  optional :max_results, :uint32, 7
  optional :timeout, :uint32, 8
end

class RpbCSBucketResp
  repeated :objects, RpbIndexObject, 1
  optional :continuation, :bytes, 2
  optional :done, :bool, 3
end

class RpbIndexObject
  required :key, :bytes, 1
  required :object, RpbGetResp, 2
end

class RpbContent
  required :value, :bytes, 1
  optional :content_type, :bytes, 2
  optional :charset, :bytes, 3
  optional :content_encoding, :bytes, 4
  optional :vtag, :bytes, 5
  repeated :links, RpbLink, 6
  optional :last_mod, :uint32, 7
  optional :last_mod_usecs, :uint32, 8
  repeated :usermeta, RpbPair, 9
  repeated :indexes, RpbPair, 10
  optional :deleted, :bool, 11
end

class RpbLink
  optional :bucket, :bytes, 1
  optional :key, :bytes, 2
  optional :tag, :bytes, 3
end

class RpbCounterUpdateReq
  required :bucket, :bytes, 1
  required :key, :bytes, 2
  required :amount, :sint64, 3
  optional :w, :uint32, 4
  optional :dw, :uint32, 5
  optional :pw, :uint32, 6
  optional :returnvalue, :bool, 7
end

class RpbCounterUpdateResp
  optional :value, :sint64, 1
end

class RpbCounterGetReq
  required :bucket, :bytes, 1
  required :key, :bytes, 2
  optional :r, :uint32, 3
  optional :pr, :uint32, 4
  optional :basic_quorum, :bool, 5
  optional :notfound_ok, :bool, 6
end

class RpbCounterGetResp
  optional :value, :sint64, 1
end
## Generated from riak_search.proto for 
require "beefcake"


class RpbSearchDoc
  include Beefcake::Message
end


class RpbSearchQueryReq
  include Beefcake::Message
end


class RpbSearchQueryResp
  include Beefcake::Message
end


class RpbSearchDoc
  repeated :fields, RpbPair, 1
end

class RpbSearchQueryReq
  required :q, :bytes, 1
  required :index, :bytes, 2
  optional :rows, :uint32, 3
  optional :start, :uint32, 4
  optional :sort, :bytes, 5
  optional :filter, :bytes, 6
  optional :df, :bytes, 7
  optional :op, :bytes, 8
  repeated :fl, :bytes, 9
  optional :presort, :bytes, 10
end

class RpbSearchQueryResp
  repeated :docs, RpbSearchDoc, 1
  optional :max_score, :float, 2
  optional :num_found, :uint32, 3
end
## Generated from riak_yokozuna.proto for 
require "beefcake"


class RpbYokozunaIndex
  include Beefcake::Message
end


class RpbYokozunaIndexGetReq
  include Beefcake::Message
end


class RpbYokozunaIndexGetResp
  include Beefcake::Message
end


class RpbYokozunaIndexPutReq
  include Beefcake::Message
end


class RpbYokozunaIndexDeleteReq
  include Beefcake::Message
end


class RpbYokozunaSchema
  include Beefcake::Message
end


class RpbYokozunaSchemaPutReq
  include Beefcake::Message
end


class RpbYokozunaSchemaGetReq
  include Beefcake::Message
end


class RpbYokozunaSchemaGetResp
  include Beefcake::Message
end


class RpbYokozunaIndex
  required :name, :bytes, 1
  optional :schema, :bytes, 2
end

class RpbYokozunaIndexGetReq
  optional :name, :bytes, 1
end

class RpbYokozunaIndexGetResp
  repeated :index, RpbYokozunaIndex, 1
end

class RpbYokozunaIndexPutReq
  required :index, RpbYokozunaIndex, 1
end

class RpbYokozunaIndexDeleteReq
  required :name, :bytes, 1
end

class RpbYokozunaSchema
  required :name, :bytes, 1
  optional :content, :bytes, 2
end

class RpbYokozunaSchemaPutReq
  required :schema, RpbYokozunaSchema, 1
end

class RpbYokozunaSchemaGetReq
  required :name, :bytes, 1
end

class RpbYokozunaSchemaGetResp
  required :schema, RpbYokozunaSchema, 1
end

    end
  end
end
