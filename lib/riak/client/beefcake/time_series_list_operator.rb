require_relative './ts_cell_codec'
require_relative './operator'

class RIak::Client::BeefcakeProtobuffsBackend
  def time_series_list_operator
    TimeSeriesListOperator.new(self)
  end

  class TimeSeriesListOperator < Operator
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

        while resp = p.expect(:TsListKeysResp, RpbListKeysResp)
          break if resp.done

          resp.keys.each do |k|
            yield k
          end
        end
      end
    end
  end
end
