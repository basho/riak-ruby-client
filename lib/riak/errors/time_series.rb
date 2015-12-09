require 'riak/errors/base'

module Riak
  class TimeSeriesError < Error
    class SerializeComplexNumberError < TimeSeriesError
      def initialize
        super t('time_series.serialize_complex_number')
      end
    end

    class SerializeRationalNumberError < TimeSeriesError
      def initialize
        super t('time_series.serialize_rational_number')
      end
    end

    class SerializeBigIntegerError < TimeSeriesError
      def initialize(bignum)
        super t('time_series.serialize_big_integer', bignum: bignum)
      end
    end
  end
end
