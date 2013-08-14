require 'riak/client/http_backend/chunked_json_streamer'

module Riak
   class Client
     class HTTPBackend
       # @private
       class BucketStreamer < ChunkedJsonStreamer
         def get_values(obj)
           obj['buckets']
         end
       end
     end
   end
 end

