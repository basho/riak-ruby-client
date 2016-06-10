require_relative './ts_cell_codec'
require_relative './operator'

class Riak::Client::BeefcakeProtobuffsBackend
  def time_series_list_operator(convert_timestamp)
    TimeSeriesListOperator.new(self, convert_timestamp)
  end

  class TimeSeriesListOperator < Operator
    def initialize(backend, convert_timestamp)
      super(backend)
      @convert_timestamp = convert_timestamp
    end

    def list(table_name, block, options = {  })
      request = TsListKeysReq.new options.merge(table: table_name)

      return streaming_list_keys(request, &block) unless block.nil?

      Riak::TimeSeries::Collection.new.tap do |key_buffer|
        streaming_list_keys(request) do |key_row|
          key_buffer << key_row
        end
      end
    end

    private

    def streaming_list_keys(request)
      backend.protocol do |p|
        p.write :TsListKeysReq, request

        codec = TsCellCodec.new(@convert_timestamp)

        while resp = p.expect(:TsListKeysResp, TsListKeysResp)
          break if resp.done
          resp.keys.each do |row|
            key_fields = codec.scalars_for row.cells
            yield key_fields
          end
        end
      end

      true
    end
  end
end
