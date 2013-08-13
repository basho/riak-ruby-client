require 'riak/client/http_backend/chunked_json_streamer'

module Riak
   class Client
     class HTTPBackend
       # @private
       class KeyStreamer < ChunkedJsonStreamer
         def get_values(obj)
           obj['keys']
         end
       end
     end
   end
 end

