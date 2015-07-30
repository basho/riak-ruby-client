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
        query = Riak::TimeSeries::Query.new test_client, query_text
        expect{ query.issue! }.to_not raise_error
      end
    end
  end

  describe 'submission interface' do
    let(:table_name){ "time_series" }
    subject{ Riak::TimeSeries::Submission.new test_client, table_name }

    let(:sample_data) do
      [
        [Time.now - 10, 'bryce', 305.37],
        [Time.now - 5, 'bryce', 300.12],
        [Time.now, 'bryce', 295.95],
      ]
    end

    it 'writes data without error' do
      subject.measurements = sample_data
      expect{ subject.write! }.to_not raise_error
    end
  end
end
