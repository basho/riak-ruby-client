class Riak::Client::BeefcakeProtobuffsBackend
  class CrdtLoader
    class CounterLoader
      def self.for_value(resp)
        return nil unless resp.counter_value
        new resp.counter_value
      end

      def initialize(counter_value)
        @value = counter_value
      end

      def rubyfy
        @value
      end
    end
  end
end
