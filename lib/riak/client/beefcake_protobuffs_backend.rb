require 'base64'
require 'riak/json'
require 'riak/client'
require 'riak/errors/failed_request'
require 'riak/client/protobuffs_backend'

module Riak
  class Client
    class BeefcakeProtobuffsBackend < ProtobuffsBackend
      def self.configured?
        begin
          require 'beefcake'
          require 'riak/client/beefcake/messages'
          require 'riak/client/beefcake/message_overlay'
          require 'riak/client/beefcake/object_methods'
          require 'riak/client/beefcake/bucket_properties_operator'
          require 'riak/client/beefcake/crdt_operator'
          require 'riak/client/beefcake/crdt_loader'
          require 'riak/client/beefcake/protocol'
          require 'riak/client/beefcake/socket'
          true
        rescue LoadError, NameError => e
          # put exception into a variable for debugging
          false
        end
      end

      def protocol
        p = Protocol.new socket
        in_request = false
        result = nil
        begin
          in_request = true
          result = yield p
          in_request = false
        ensure
          reset_socket if in_request
        end
        return result
      end

      def new_socket
        BeefcakeSocket.new @node.host, @node.pb_port, authentication: client.authentication
      end

      def ping
        protocol do |p|
          p.write :PingReq
          p.expect :PingResp
        end
      end

      def get_client_id
        protocol do |p|
          p.write :GetClientIdReq
          p.expect(:GetClientIdResp, RpbGetClientIdResp).client_id
        end
      end

      def server_info
        resp = protocol do |p|
          p.write :GetServerInfoReq
          p.expect(:GetServerInfoResp, RpbGetServerInfoResp)
        end

        { node: resp.node, server_version: resp.server_version }
      end

      def set_client_id(id)
        value = case id
                when Integer
                  [id].pack("N")
                else
                  id.to_s
                end
        req = RpbSetClientIdReq.new(:client_id => value)
        protocol do |p|
          p.write :SetClientIdReq, req
          p.expect :SetClientIdResp
        end
        return true
      end

      def fetch_object(bucket, key, options={})
        options = prune_unsupported_options(:GetReq, normalize_quorums(options))
        bucket = Bucket === bucket ? bucket.name : bucket
        req = RpbGetReq.new(options.merge(:bucket => maybe_encode(bucket), :key => maybe_encode(key)))

        resp = protocol do |p|
          p.write :GetReq, req
          p.expect :GetResp, RpbGetResp, empty_body_acceptable: true
        end

        if :empty == resp
          raise Riak::ProtobuffsFailedRequest.new(:not_found, t('not_found'))
        end

        template = RObject.new(client.bucket(bucket), key)
        load_object(resp, template)
      end

      def reload_object(robject, options={})
        options = normalize_quorums(options)
        options[:bucket] = maybe_encode(robject.bucket.name)
        options[:key] = maybe_encode(robject.key)
        options[:if_modified] = maybe_encode Base64.decode64(robject.vclock) if robject.vclock
        req = RpbGetReq.new(prune_unsupported_options(:GetReq, options))

        resp = protocol do |p|
          p.write :GetReq, req
          p.expect :GetResp, RpbGetResp, empty_body_acceptable: true
        end

        if :empty == resp
          raise Riak::ProtobuffsFailedRequest.new(:not_found, t('not_found'))
        end

        load_object(resp, robject)
      end

      def store_object(robject, options={})
        options[:return_body] ||= options[:returnbody]
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

        resp = protocol do |p|
          p.write(:PutReq, req)
          p.expect :PutResp, RpbPutResp, empty_body_acceptable: true
        end

        return true if :empty == resp

        load_object resp, robject
      end

      def delete_object(bucket, key, options={})
        bucket = Bucket === bucket ? bucket.name : bucket
        options = normalize_quorums(options)
        options[:bucket] = maybe_encode(bucket)
        options[:key] = maybe_encode(key)
        options[:vclock] = Base64.decode64(options[:vclock]) if options[:vclock]
        req = RpbDelReq.new(prune_unsupported_options(:DelReq, options))

        protocol do |p|
          p.write :DelReq, req
          p.expect :DelResp
        end
        
        return true
      end

      def get_counter(bucket, key, options={})
        bucket = bucket.name if bucket.is_a? Bucket 

        options = normalize_quorums(options)
        options[:bucket] = bucket
        options[:key] = key
        
        request = RpbCounterGetReq.new options
        
        resp = protocol do |p|
          p.write :CounterGetReq, request
          p.expect :CounterGetResp, RpbCounterGetResp, empty_body_acceptable: true
        end
        
        if :empty == resp
          return 0
        end

        return resp.value || 0
      end

      def post_counter(bucket, key, amount, options={})
        bucket = bucket.name if bucket.is_a? Bucket

        options = normalize_quorums(options)
        options[:bucket] = bucket
        options[:key] = key
        # TODO: raise if amount doesn't fit in sint64
        options[:amount] = amount
        options[:returnvalue] = options[:returnvalue] || options[:return_value]
        
        request = RpbCounterUpdateReq.new options

        resp = protocol do |p|
          p.write :CounterUpdateReq, request
          p.expect :CounterUpdateResp, RpbCounterUpdateResp, empty_body_acceptable: true
        end

        return nil if :empty == resp
        
        return resp.value
      end

      def get_bucket_props(bucket, options = {  })
        bucket_properties_operator.get bucket, options
      end

      def set_bucket_props(bucket, props, type=nil)
        bucket_properties_operator.put bucket, props, type: type
      end

      def reset_bucket_props(bucket, options)
        bucket = bucket.name if Bucket === bucket
        req = RpbResetBucketReq.new(bucket: maybe_encode(bucket),
                                    type: options[:type])

        protocol do |p|
          p.write :ResetBucketReq, req
          p.expect :ResetBucketResp
        end
      end

      def get_bucket_type_props(bucket_type)
        bucket_type = bucket_type.name if bucket_type.is_a? BucketType
        req = RpbGetBucketTypeReq.new type: bucket_type

        resp = protocol do |p|
          p.write :GetBucketTypeReq, req
          p.expect(:GetBucketResp, RpbGetBucketResp)
        end

        resp.props.to_hash
      end

      def list_keys(bucket, options={}, &block)
        bucket = bucket.name if Bucket === bucket
        req = RpbListKeysReq.new(options.merge(:bucket => maybe_encode(bucket)))

        keys = []

        protocol do |p|
          p.write :ListKeysReq, req

          while msg = p.expect(:ListKeysResp, RpbListKeysResp)
            break if msg.done
            if block_given?
              yield msg.keys
            else
              keys += msg.keys
            end
          end
        end

        return keys unless block_given?

        return true
      end

      # override the simple list_buckets
      def list_buckets(options={}, &blk)
        if block_given? 
          return streaming_list_buckets options, &blk
        end
        
        raise t("streaming_bucket_list_without_block") if options[:stream]
        
        request = RpbListBucketsReq.new options

        resp = protocol do |p|
          p.write :ListBucketsReq, request

          p.expect :ListBucketsResp, RpbListBucketsResp, empty_body_acceptable: true
        end

        return [] if :empty == resp

        resp.buckets
      end

      def mapred(mr, &block)
        raise MapReduceError.new(t("empty_map_reduce_query")) if mr.query.empty? && !mapred_phaseless?
        req = RpbMapRedReq.new(:request => mr.to_json, :content_type => "application/json")
        
        results = MapReduce::Results.new(mr)
        
        protocol do |p|
          p.write :MapRedReq, req
          while msg = p.expect(:MapRedResp, RpbMapRedResp)
            break if msg.done
            if block_given?
              yield msg.phase, JSON.parse(msg.response)
            else
              results.add msg.phase, JSON.parse(msg.response)
            end
          end
        end
        
        block_given? || results.report
      end

      def get_index(bucket, index, query, query_options={}, &block)
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

        options.merge!(:bucket => bucket, :index => index.to_s)
        options.merge!(query_options)
        options[:stream] = block_given?

        req = RpbIndexReq.new(options)

        protocol do |p|
          p.write :IndexReq, req
          decode_index_response(p, &block)
        end
      end

      def search(index, query, options={})
        return super unless pb_search?
        options = options.symbolize_keys
        options[:op] = options.delete(:'q.op') if options[:'q.op']
        req = RpbSearchQueryReq.new(options.merge(:index => index || 'search', :q => query))

        resp = protocol do |p|
          p.write :SearchQueryReq, req
          p.expect :SearchQueryResp, RpbSearchQueryResp
        end

        resp.docs = [] if resp.docs.nil?

        ret = { 'max_score' => resp.max_score, 'num_found' => resp.num_found }
        ret['docs'] = resp.docs.map { |d| decode_doc d }

        return ret
      end

      def create_search_index(name, schema=nil, n_val=nil)
        index = RpbYokozunaIndex.new(:name => name, :schema => schema, :n_val => n_val)
        req = RpbYokozunaIndexPutReq.new(:index => index)

        protocol do |p|
          p.write :YokozunaIndexPutReq, req
          p.expect :PutResp
        end
      end

      def get_search_index(name)
        req = RpbYokozunaIndexGetReq.new(:name => name)
        begin 
          resp = protocol do |p|
            p.write :YokozunaIndexGetReq, req
            p.expect :YokozunaIndexGetResp, RpbYokozunaIndexGetResp, empty_body_acceptable: true
          end
        rescue ProtobuffsErrorResponse => e
          if e.code == 0 && e.original_message =~ /notfound/
            raise Riak::ProtobuffsFailedRequest.new(:not_found, t('not_found'))
          end

          raise e
        end

        resp
      end

      def delete_search_index(name)
        req = RpbYokozunaIndexDeleteReq.new(:name => name)
        protocol do |p|
          p.write :YokozunaIndexDeleteReq, req
          p.expect :DelResp
        end
        true
      end

      def create_search_schema(name, content)
        schema = RpbYokozunaSchema.new(:name => name, :content => content)
        req = RpbYokozunaSchemaPutReq.new(:schema => schema)

        protocol do |p|
          p.write :YokozunaSchemaPutReq, req
          p.expect :PutResp
        end
        true
      end

      def get_search_schema(name)
        req = RpbYokozunaSchemaGetReq.new(:name => name)

        begin
          resp = protocol do |p|
            p.write :YokozunaSchemaGetReq, req
            p.expect :YokozunaSchemaGetResp, RpbYokozunaSchemaGetResp
          end
        rescue ProtobuffsErrorResponse => e
          if e.code == 0 && e.original_message =~ /notfound/
            raise Riak::ProtobuffsFailedRequest.new(:not_found, t('not_found'))
          end

          raise e
        end

        resp.schema ? resp.schema : resp
      end

      def write_protobuff(code, message)
        encoded = message.encode
        header = [encoded.length+1, MESSAGE_CODES.index(code)].pack("NC")
        socket.write(header + encoded)
      end

      private
      def decode_response(*args)
        header = socket.read(5)
        raise ProtobuffsFailedHeader.new if header.nil?
        msglen, msgcode = header.unpack("NC")
        if msglen == 1
          case MESSAGE_CODES[msgcode]
          when :ListBucketsResp,  
               :IndexResp
            []
          when :GetResp,
               :YokozunaSchemaGetResp
            raise Riak::ProtobuffsFailedRequest.new(:not_found, t('not_found'))
          when :CounterGetResp,
               :CounterUpdateResp
            0
          else
            false
          end
        else
          message = socket.read(msglen-1)
          case MESSAGE_CODES[msgcode]
          when :ErrorResp
            res = RpbErrorResp.decode(message)
            raise Riak::ProtobuffsFailedRequest.new(res.errcode, res.errmsg)
          end
        end
      rescue SystemCallError, SocketError => e
        reset_socket
        raise
      end

      def streaming_list_buckets(options = {})
        request = RpbListBucketsReq.new(options.merge(stream: true))
        write_protobuff :ListBucketsReq, request
        loop do
          header = socket.read 5
          raise SocketError, "Unexpected EOF on PBC socket" if header.nil?
          len, code = header.unpack 'NC'
          if MESSAGE_CODES[code] != :ListBucketsResp
            raise SocketError, "Unexpected non-ListBucketsResp during streaming list buckets"
          end

          message = socket.read(len - 1)
          section = RpbListBucketsResp.decode message
          yield section.buckets

          return if section.done
        end
      end

      def decode_index_response(p)
        loop do
          resp = p.expect :IndexResp, RpbIndexResp, empty_body_acceptable: true

          if :empty == resp
            return if block_given?
            return IndexCollection.new_from_protobuf(RpbIndexResp.decode(''))
          end

          if !block_given?
            return IndexCollection.new_from_protobuf(resp)
          end
          
          content = resp.keys || resp.results || []
          yield content
          
          return if resp.done
        end
      rescue ProtobuffsErrorResponse => err
        if match = err.message.match(/indexes_not_supported,(\w+)/)
          old_err = err
          err = ProtobuffsFailedRequest.new(:indexes_not_supported, 
                                            t('index.wrong_backend', backend: match[1])
                                            )
        end

        raise err
      end

      def decode_doc(doc)
        Hash[doc.fields.map {|p| [ force_utf8(p.key), force_utf8(p.value) ] }]
      end

      def force_utf8(str)
        # Search returns strings that should always be valid UTF-8
        ObjectMethods::ENCODING ? str.force_encoding('UTF-8') : str
      end
    end
  end
end
