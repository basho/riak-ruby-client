require 'bigdecimal'

class Riak::Client::BeefcakeProtobuffsBackend
  class TsCellCodec
    def cells_for(measures)
      measures.map{ |m| cell_for m }
    end

    def scalars_for(cells)
      cells.map{ |c| scalar_for c }
    end

    def cell_for(measure)
      TsCell.new case measure
                 when String
                   { varchar_value: measure }
                 when Fixnum
                   { sint64_value: measure }
                 when Bignum
                   { sint64_value: check_bignum_range(measure) }
                 when Float
                   { double_value: measure }
                 when BigDecimal
                   { double_value: measure.to_f }
                 when Rational
                   fail Riak::TimeSeriesError::SerializeRationalNumberError
                 when Complex
                   fail Riak::TimeSeriesError::SerializeComplexNumberError
                 when Time
                   seconds = measure.to_f
                   milliseconds = seconds * 1000
                   truncated_ms = milliseconds.to_i
                   { timestamp_value: truncated_ms }
                 when TrueClass, FalseClass
                   { boolean_value: measure }
                 when nil
                   {  }
                 end
    end

    def scalar_for(cell)
      cell.varchar_value ||
        cell.sint64_value ||
        cell.double_value ||
        timestamp(cell) ||
        cell.boolean_value # boolean_value is last, so we can get either false, nil, or true
    end

    private
    def check_bignum_range(bignum)
      if (bignum > -0x8000000000000000) && (bignum < 0x7FFFFFFFFFFFFFFF)
        return bignum
      end

      fail Riak::TimeSeriesError::SerializeBigIntegerError, bignum
    end

    def timestamp(cell)
      return false unless Integer === cell.timestamp_value
      tsv = cell.timestamp_value
      secs = tsv / 1000
      msec = tsv % 1000
      Time.at(secs, msec * 1000)
    end
  end
end
