class Riak::Client::BeefcakeProtobuffsBackend
  class TsCellCodec
    def cell_for(measure)
      TsCell.new case measure
                 when String
                   { binary_value: measure }
                 when Integer
                   { integer_value: measure }
                 when Float
                   { double_value: measure }
                 when Numeric
                   { numeric_value: measure.to_s }
                 when Time
                   { timestamp_value: measure.to_i }
                 when TrueClass, FalseClass
                   { boolean_value: measure }
                 end
    end

    def scalar_for(cell)
      cell.binary_value ||
        cell.integer_value ||
        cell.double_value ||
        cell.float_value ||
        numeric(cell) ||
        timestamp(cell) ||
        cell.boolean_value
      # boolean_value is last, so we can get either false, nil, or true
    end

    private
    def numeric(cell)
      return false unless cell.numeric_value.is_a? String
      return cell.numeric_value.to_i unless cell.include? "."
      cell.numeric_value.to_f
    end

    def timestamp(cell)
      return false unless cell.timestamp_value.is_a? Integer
      Time.at(cell / 1000)
    end
  end
end
