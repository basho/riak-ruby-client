# Copyright 2010-present Basho Technologies, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'bigdecimal'

class Riak::Client::BeefcakeProtobuffsBackend
  class TsCellCodec
    attr_accessor :convert_timestamp

    def initialize(convert_timestamp = false)
      @convert_timestamp = convert_timestamp
    end

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
      return false unless cell.timestamp_value.is_a? Integer
      return cell.timestamp_value unless @convert_timestamp
      tsv = cell.timestamp_value
      secs = tsv / 1000
      msec = tsv % 1000
      Time.at(secs, msec * 1000)
    end
  end
end
