module Riak
  class Client
    # A float value which decays exponentially toward 0 over time.
    # @private
    class Decaying
      attr_accessor :e
      attr_accessor :p

      # @param [Hash] opts options
      # @option options [Float] :p (0.0) The initial value
      # @option options [Float] :e (Math::E) Exponent base
      # @option options [Float] :r (Math.log(0.5) / 10) Timescale
      #   factor - defaulting to decay 50% every 10 seconds
      def initialize(opts = {})
        @p = opts[:p] || 0.0
        @e = opts[:e] || Math::E
        @r = opts[:r] || Math.log(0.5) / 10
        @t0 = Time.now
      end

      # Add to current value.
      # @param [Float] d the value to add
      def <<(d)
        @p = value + d
      end

      # @return [Float] the current value (adjusted for the time decay)
      def value
        now = Time.now
        dt = now - @t0
        @t0 = now
        @p = @p * (@e ** (@r * dt))
      end
    end
  end
end
