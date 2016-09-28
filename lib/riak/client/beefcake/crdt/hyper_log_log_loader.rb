class Riak::Client::BeefcakeProtobuffsBackend
  class CrdtLoader
    class HyperLogLogLoader
      def self.for_value(resp)
        return nil unless resp.hll_value
        new resp.hll_value
      end

      def initialize(hll_value)
        @value = hll_value
      end

      def rubyfy
        ::Set.new @value
      end
    end
  end
end
