require 'spec_helper'
require 'riak'

describe 'Time Series', test_client: true, integration: true do
  describe 'query interface' do
    describe 'creating collections' do

      let(:table_name){  "time_series" }
      let(:query_text){ <<-SQL.lines.map(&:strip).join ' ' }
create table #{ table_name } (
time timestamp not null,
user_id varchar not null,
temperature_k float,
primary key (time))
SQL

      it 'round-trips a create request without error' do
pp query_text
        query = Riak::TimeSeries::Query.new test_client, query_text
        expect{ query.issue! }.to_not raise_error
      end
    end
  end
end
