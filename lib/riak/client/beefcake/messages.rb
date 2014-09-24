require 'beefcake'

module Riak
  class Client
    # @private
    class BeefcakeProtobuffsBackend
      # Embedded messages
      class RpbPair
        include Beefcake::Message
        required :key,   :bytes, 1
        optional :value, :bytes, 2
      end

      # module-function pair for commit hooks and other properties that take
      # functions
      class RpbModFun
        include Beefcake::Message

        required :module,   :bytes, 1
        required :function, :bytes, 2
      end

      class RpbCommitHook
        include Beefcake::Message

        optional :modfun, RpbModFun, 1
        optional :name,   :bytes,    2
      end

      class RpbBucketProps
        include Beefcake::Message

        # riak_core_app
        optional :n_val,           :uint32,       1
        optional :allow_mult,      :bool,         2
        optional :last_write_wins, :bool,         3

        # riak_core values with special handling, see below
        repeated :precommit,       RpbCommitHook, 4
        optional :has_precommit,   :bool,         5, :default => false
        repeated :postcommit,      RpbCommitHook, 6
        optional :has_postcommit,  :bool,         7, :default => false

        optional :chash_keyfun,    RpbModFun,     8

        # riak_kv_app
        optional :linkfun,         RpbModFun,     9
        optional :old_vclock,      :uint32,       10
        optional :young_vclock,    :uint32,       11
        optional :big_vclock,      :uint32,       12
        optional :small_vclock,    :uint32,       13
        optional :pr,              :uint32,       14
        optional :r,               :uint32,       15
        optional :w,               :uint32,       16
        optional :pw,              :uint32,       17
        optional :dw,              :uint32,       18
        optional :rw,              :uint32,       19
        optional :basic_quorum,    :bool,         20
        optional :notfound_ok,     :bool,         21

        # riak_kv_multi_backend
        optional :backend,         :bytes,        22

        # riak_search bucket fixup
        optional :search,          :bool,         23

        module RpbReplMode
          FALSE = 0
          REALTIME = 1
          FULLSYNC = 2
          TRUE = 3
        end

        optional :repl,            RpbReplMode,   24

        # "repeated" elements with zero items are indistinguishable
        # from a nil, so we have to manage has_precommit/has_postcommit
        # flags.
        def precommit=(newval)
          @precommit = newval
          @has_precommit = !!newval 
        end

        def has_precommit=(newval)
          @has_precommit = newval
          @precommit ||= [] if newval
        end

        def postcommit=(newval)
          @postcommit = newval
          @has_postcommit = !!newval 
        end

        def has_postcommit=(newval)
          @has_postcommit = newval
          @postcommit ||= [] if newval
        end
      end

      class RpbLink
        include Beefcake::Message
        optional :bucket, :bytes, 1
        optional :key,    :bytes, 2
        optional :tag,    :bytes, 3
      end

      class RpbContent
        include Beefcake::Message
        required :value,            :bytes,  1
        optional :content_type,     :bytes,  2
        optional :charset,          :bytes,  3
        optional :content_encoding, :bytes,  4
        optional :vtag,             :bytes,  5
        repeated :links,            RpbLink, 6
        optional :last_mod,         :uint32, 7
        optional :last_mod_usecs,   :uint32, 8
        repeated :usermeta,         RpbPair, 9
        repeated :indexes,          RpbPair, 10
      end

      # Primary messages
      class RpbErrorResp
        include Beefcake::Message
        required :errmsg,  :bytes,  1
        required :errcode, :uint32, 2
      end

      class RpbGetClientIdResp
        include Beefcake::Message
        required :client_id, :bytes, 1
      end

      class RpbSetClientIdReq
        include Beefcake::Message
        required :client_id, :bytes, 1
      end

      class RpbGetServerInfoResp
        include Beefcake::Message
        optional :node,           :bytes, 1
        optional :server_version, :bytes, 2
      end

      class RpbGetReq
        include Beefcake::Message
        required :bucket,        :bytes,  1
        required :key,           :bytes,  2
        optional :r,             :uint32, 3
        optional :pr,            :uint32, 4
        optional :basic_quorum,  :bool,   5
        optional :notfound_ok,   :bool,   6
        optional :if_modified,   :bytes,  7
        optional :head,          :bool,   8
        optional :deletedvclock, :bool,   9
        optional :timeout,       :uint32, 10
        optional :sloppy_quorum, :bool,   11
        optional :n_val,         :uint32, 12
      end

      class RpbGetResp
        include Beefcake::Message
        repeated :content,   RpbContent, 1
        optional :vclock,    :bytes,     2
        optional :unchanged, :bool,      3
      end

      class RpbPutReq
        include Beefcake::Message
        required :bucket,          :bytes,     1
        optional :key,             :bytes,     2
        optional :vclock,          :bytes,     3
        required :content,         RpbContent, 4
        optional :w,               :uint32,    5
        optional :dw,              :uint32,    6
        optional :returnbody,      :bool,      7
        optional :pw,              :uint32,    8
        optional :if_not_modified, :bool,      9
        optional :if_none_match,   :bool,      10
        optional :return_head,     :bool,      11
        optional :timeout,         :uint32,    12
        optional :asis,            :bool,      13
        optional :sloppy_quorum,   :bool,      14
        optional :n_val,           :uint32,    15
      end

      class RpbPutResp
        include Beefcake::Message
        repeated :content, RpbContent, 1
        optional :vclock,  :bytes,     2
        optional :key,     :bytes,     3
      end

      class RpbDelReq
        include Beefcake::Message
        required :bucket,        :bytes,  1
        required :key,           :bytes,  2
        optional :rw,            :uint32, 3
        optional :vclock,        :bytes,  4
        optional :r,             :uint32, 5
        optional :w,             :uint32, 6
        optional :pr,            :uint32, 7
        optional :pw,            :uint32, 8
        optional :dw,            :uint32, 9
        optional :timeout,       :uint32, 10
        optional :sloppy_quorum, :bool,   11
        optional :n_val,         :uint32, 12
      end

      class RpbListBucketsReq
        include Beefcake::Message
        optional :timeout, :uint32, 1
        optional :stream, :bool, 2
      end

      class RpbListBucketsResp
        include Beefcake::Message
        repeated :buckets, :bytes, 1
        optional :done, :bool, 2
      end

      class RpbListKeysReq
        include Beefcake::Message
        required :bucket, :bytes, 1
        optional :timeout, :uint32, 2
      end

      class RpbListKeysResp
        include Beefcake::Message
        repeated :keys, :bytes, 1
        optional :done, :bool,  2
      end

      class RpbGetBucketReq
        include Beefcake::Message
        required :bucket, :bytes, 1
      end

      class RpbGetBucketResp
        include Beefcake::Message
        required :props, RpbBucketProps, 1
      end

      class RpbSetBucketReq
        include Beefcake::Message
        required :bucket, :bytes,         1
        required :props,  RpbBucketProps, 2
      end

      class RpbResetBucketReq
        include Beefcake::Message
      end

      class RpbMapRedReq
        include Beefcake::Message
        required :request,      :bytes, 1
        required :content_type, :bytes, 2
      end

      class RpbMapRedResp
        include Beefcake::Message
        optional :phase,    :uint32, 1
        optional :response, :bytes,  2
        optional :done,     :bool,   3
      end

      class RpbIndexReq
        include Beefcake::Message
        module IndexQueryType
          EQ = 0
          RANGE = 1
        end

        required :bucket,       :bytes,         1
        required :index,        :bytes,         2
        required :qtype,        IndexQueryType, 3
        optional :key,          :bytes,         4
        optional :range_min,    :bytes,         5
        optional :range_max,    :bytes,         6
        optional :return_terms, :bool,          7
        optional :stream,       :bool,          8
        optional :max_results,  :uint32,        9
        optional :continuation, :bytes,         10
        optional :timeout,      :uint32,        11
      end

      class RpbIndexResp
        include Beefcake::Message
        repeated :keys,         :bytes,  1
        repeated :results,      RpbPair, 2
        optional :continuation, :bytes,  3
        optional :done,         :bool,   4
      end

      class RpbSearchDoc
        include Beefcake::Message
        # We have to name this differently than the .proto file does
        # because Beefcake uses 'fields' as an instance method.
        repeated :properties, RpbPair, 1
      end

      class RpbSearchQueryReq
        include Beefcake::Message
        required :q,       :bytes,  1
        required :index,   :bytes,  2
        optional :rows,    :uint32, 3
        optional :start,   :uint32, 4
        optional :sort,    :bytes,  5
        optional :filter,  :bytes,  6
        optional :df,      :bytes,  7
        optional :op,      :bytes,  8
        repeated :fl,      :bytes,  9
        optional :presort, :bytes, 10
      end

      class RpbSearchQueryResp
        include Beefcake::Message
        repeated :docs, RpbSearchDoc, 1, :default => []
        optional :max_score, :float,  2
        optional :num_found, :uint32, 3
      end

      class RpbResetBucketReq
        include Beefcake::Message
        required :bucket, :bytes, 1
      end

      class RpbCSBucketReq
        include Beefcake::Message
        required :bucket,       :bytes,  1
        required :start_key,    :bytes,  2
        optional :end_key,      :bytes,  3
        optional :start_incl,   :bool,   4, default: true
        optional :end_incl,     :bool,   5, default: false
        optional :continuation, :bytes,  6
        optional :max_results,  :uint32, 7
        optional :timeout,      :uint32, 8
      end
      
      class RpbIndexObject
        include Beefcake::Message
        required :key,    :bytes,     1
        required :object, RpbGetResp, 2
      end

      class RpbCSBucketResp
        include Beefcake::Message
        repeated :objects,      RpbIndexObject, 1
        optional :continuation, :bytes,         2
        optional :done,         :bool,          3
      end

      class RpbCounterUpdateReq
        include Beefcake::Message
        required :bucket,      :bytes,  1
        required :key,         :bytes,  2
        required :amount,      :sint64, 3
        optional :w,           :uint32, 4
        optional :dw,          :uint32, 5
        optional :pw,          :uint32, 6
        optional :returnvalue, :bool,   7
      end

      class RpbCounterUpdateResp
        include Beefcake::Message
        optional :value, :sint64, 1
      end

      class RpbCounterGetReq
        include Beefcake::Message
        required :bucket,       :bytes,  1
        required :key,          :bytes,  2
        optional :r,            :uint32, 3
        optional :pr,           :uint32, 4
        optional :basic_quorum, :bool,   5
        optional :notfound_ok,  :bool,   6
      end

      class RpbCounterGetResp
        include Beefcake::Message
        optional :value, :sint64, 1
      end
    end
  end
end
