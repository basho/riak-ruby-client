require 'base64'
require 'riak/json'
require 'riak/client'
require 'riak/failed_request'
require 'riak/client/protobuffs_backend'

module Riak
  class Client
    class BeefcakeProtobuffsBackend < ProtobuffsBackend
      def self.configured?
        begin
          require 'beefcake'
          require 'riak/client/beefcake/messages'
          require 'riak/client/beefcake/object_methods'
          true
        rescue LoadError, NameError
          false
        end
      end

      def set_client_id(id)
        value = case id
                when Integer
                  [id].pack("N")
                else
                  id.to_s
                end
        req = RpbSetClientIdReq.new(:client_id => value)
        write_protobuff(:SetClientIdReq, req)
        decode_response
      end

      def fetch_object(bucket, key, options={})
        options = prune_unsupported_options(:GetReq, normalize_quorums(options))
        bucket = Bucket === bucket ? bucket.name : bucket
        req = RpbGetReq.new(options.merge(:bucket => maybe_encode(bucket), :key => maybe_encode(key)))
        write_protobuff(:GetReq, req)
        decode_response(RObject.new(client.bucket(bucket), key))
      end

      def reload_object(robject, options={})
        options = normalize_quorums(options)
        options[:bucket] = maybe_encode(robject.bucket.name)
        options[:key] = maybe_encode(robject.key)
        options[:if_modified] = maybe_encode Base64.decode64(robject.vclock) if robject.vclock
        req = RpbGetReq.new(prune_unsupported_options(:GetReq, options))
        write_protobuff(:GetReq, req)
        decode_response(robject)
      end

      def store_object(robject, options={})
        options = normalize_quorums(options)
        if robject.prevent_stale_writes
          unless pb_conditionals?
            other = fetch_object(robject.bucket, robject.key)
            raise Riak::ProtobuffsFailedRequest.new(:stale_object, t("stale_write_prevented")) unless other.vclock == robject.vclock
          end
          if robject.vclock
            options[:if_not_modified] = true
          else
            options[:if_none_match] = true
          end
        end
        req = dump_object(robject, prune_unsupported_options(:PutReq, options))
        write_protobuff(:PutReq, req)
        decode_response(robject)
      end

      def delete_object(bucket, key, options={})
        bucket = Bucket === bucket ? bucket.name : bucket
        options = normalize_quorums(options)
        options[:bucket] = maybe_encode(bucket)
        options[:key] = maybe_encode(key)
        options[:vclock] = Base64.decode64(options[:vclock]) if options[:vclock]
        req = RpbDelReq.new(prune_unsupported_options(:DelReq, options))
        write_protobuff(:DelReq, req)
        decode_response
      end

      def get_bucket_props(bucket)
        bucket = bucket.name if Bucket === bucket
        req = RpbGetBucketReq.new(:bucket => maybe_encode(bucket))
        write_protobuff(:GetBucketReq, req)
        resp = normalize_quorums decode_response
        normalized = normalize_hooks resp
        pp normalized
        normalized.stringify_keys
      end

      def set_bucket_props(bucket, props)
        bucket = bucket.name if Bucket === bucket
        props = props.slice('n_val', 'allow_mult')
        req = RpbSetBucketReq.new(:bucket => maybe_encode(bucket), :props => RpbBucketProps.new(props))
        write_protobuff(:SetBucketReq, req)
        decode_response
      end

      def reset_bucket_props(bucket)
        bucket = bucket.name if Bucket === bucket
        req = RpbResetBucketReq.new(:bucket => maybe_encode(bucket))
        write_protobuff(:ResetBucketReq)
        decode_response
      end

      def list_keys(bucket, &block)
        bucket = bucket.name if Bucket === bucket
        req = RpbListKeysReq.new(:bucket => maybe_encode(bucket))
        write_protobuff(:ListKeysReq, req)
        keys = []
        while msg = decode_response
          break if msg.done
          if block_given?
            yield msg.keys
          else
            keys += msg.keys
          end
        end
        block_given? || keys
      end

      def mapred(mr, &block)
        raise MapReduceError.new(t("empty_map_reduce_query")) if mr.query.empty? && !mapred_phaseless?
        req = RpbMapRedReq.new(:request => mr.to_json, :content_type => "application/json")
        write_protobuff(:MapRedReq, req)
        results = MapReduce::Results.new(mr)
        while msg = decode_response
          break if msg.done
          if block_given?
            yield msg.phase, JSON.parse(msg.response)
          else
            results.add msg.phase, JSON.parse(msg.response)
          end
        end
        block_given? || results.report
      end

      def get_index(bucket, index, query)
        return super unless pb_indexes?
        bucket = bucket.name if Bucket === bucket
        if Range === query
          options = {
            :qtype => RpbIndexReq::IndexQueryType::RANGE,
            :range_min => query.begin.to_s,
            :range_max => query.end.to_s
          }
        else
          options = {
            :qtype => RpbIndexReq::IndexQueryType::EQ,
            :key => query.to_s
          }
        end
        req = RpbIndexReq.new(options.merge(:bucket => bucket, :index => index))
        write_protobuff(:IndexReq, req)
        decode_response
      end

      def search(index, query, options={})
        return super unless pb_search?
        options = options.symbolize_keys
        options[:op] = options.delete(:'q.op') if options[:'q.op']
        req = RpbSearchQueryReq.new(options.merge(:index => index || 'search', :q => query))
        write_protobuff(:SearchQueryReq, req)
        decode_response
      end

      private
      def write_protobuff(code, message)
        encoded = message.encode
        header = [encoded.length+1, MESSAGE_CODES.index(code)].pack("NC")
        socket.write(header + encoded)
      end

      def decode_response(*args)
        header = socket.read(5)
        raise SocketError, "Unexpected EOF on PBC socket" if header.nil?
        msglen, msgcode = header.unpack("NC")
        if msglen == 1
          case MESSAGE_CODES[msgcode]
          when :PingResp, :SetClientIdResp, :PutResp, :DelResp, :SetBucketResp
            true
          when :ListBucketsResp, :ListKeysResp, :IndexResp
            []
          when :GetResp
            raise Riak::ProtobuffsFailedRequest.new(:not_found, t('not_found'))
          else
            false
          end
        else
          message = socket.read(msglen-1)
          case MESSAGE_CODES[msgcode]
          when :ErrorResp
            res = RpbErrorResp.decode(message)
            raise Riak::ProtobuffsFailedRequest.new(res.errcode, res.errmsg)
          when :GetClientIdResp
            res = RpbGetClientIdResp.decode(message)
            res.client_id
          when :GetServerInfoResp
            res = RpbGetServerInfoResp.decode(message)
            {:node => res.node, :server_version => res.server_version}
          when :GetResp
            res = RpbGetResp.decode(message)
            load_object(res, args.first)
          when :PutResp
            res = RpbPutResp.decode(message)
            load_object(res, args.first)
          when :ListBucketsResp
            res = RpbListBucketsResp.decode(message)
            res.buckets
          when :ListKeysResp
            RpbListKeysResp.decode(message)
          when :GetBucketResp
            res = RpbGetBucketResp.decode(message)
            res.props.to_hash.stringify_keys
          when :MapRedResp
            RpbMapRedResp.decode(message)
          when :IndexResp
            res = RpbIndexResp.decode(message)
            res.keys
          when :SearchQueryResp
            res = RpbSearchQueryResp.decode(message)
            { 'docs' => res.docs.map {|d| decode_doc(d) },
              'max_score' => res.max_score,
              'num_found' => res.num_found }
          end
        end
      rescue SystemCallError, SocketError => e
        reset_socket
        raise
      end

      def decode_doc(doc)
        Hash[doc.properties.map {|p| [ force_utf8(p.key), force_utf8(p.value) ] }]
      end

      def force_utf8(str)
        # Search returns strings that should always be valid UTF-8
        ObjectMethods::ENCODING ? str.force_encoding('UTF-8') : str
      end

      def normalize_hooks(message)
        message.dup.tap do |o|
          %w{chash_keyfun linkfun}.each do |k|
            o[k] = {'mod' => message[k].module, 'fun' => message[k].function}
          end
          %w{precommit postcommit}.each do |k|
            orig = message[k]
            o[k] = orig.map do |hook|
              if hook.modfun
                {'mod' => hook.modfun.module, 'fun' => hook.modfun.function}
              else
                hook.name
              end
            end
          end
        end
      end
    end
  end
end
