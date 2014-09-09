module Riak
  class Client
    class BeefcakeProtobuffsBackend
      class CrdtLoader
        class SetLoader
          def self.for_value(resp)
            return nil unless resp.set_value
            new resp.set_value
          end

          def initialize(set_value)
            @value = set_value
          end

          def rubyfy
            ::Set.new @value
          end
        end
      end
    end
  end
end
