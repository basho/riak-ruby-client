require 'spec_helper'
require 'riak'

describe 'Time Series', test_client: true, integration: true do
  let(:table_name){ 'GeoCheckin' }

  let(:now){ Time.now }
  let(:now_range_str) do
    past = (now.to_i - 100) * 1000
    future = (now.to_i + 100) * 1000
    "time > #{ past } AND time < #{ future }"
  end

  let(:family){ 'family-' + random_key }
  let(:series){ 'series-' + random_key }

  let(:key){ [family, series, now] }
  let(:datum){ [*key, 'cloudy', 27.1] }

  let(:family_series_str) do
    "myfamily = '#{family}' AND myseries = '#{series}'"
  end

  let(:query) do
    <<-SQL
SELECT * FROM #{table_name}
WHERE
  #{family_series_str} AND
  #{now_range_str}
SQL
  end

  let(:stored_datum_expectation) do
    submission = Riak::TimeSeries::Submission.new test_client, table_name
    submission.measurements = [datum]
    expect{ submission.write! }.to_not raise_error
  end

  describe 'query interface' do
    subject{ Riak::TimeSeries::Query.new test_client, query }

    it 'queries data without error' do
      stored_datum_expectation

      expect{ subject.issue! }.to_not raise_error
      expect(subject.results).to be
    end
  end

  describe 'single-key get interface' do
    subject{ Riak::TimeSeries::Read.new test_client, table_name }
    it 'retrieves data without error' do
      stored_datum_expectation

      subject.key = key
      result = nil
      expect{ result = subject.read! }.to_not raise_error
      expect(result).to be
    end
  end

  describe 'single-key delete interface' do
    it 'deletes data without error'
  end

  describe 'submission interface' do
    it 'writes data without error' do
      stored_datum_expectation
    end
  end
end
