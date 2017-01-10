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

require 'spec_helper'
require 'riak'

describe 'Time Series',
         test_client: true, integration: true, time_series: true do
  let(:table_name){ 'GeoCheckin' }
  let(:extended_table_name){ 'timeseries-' + random_key }

  let(:now_ts) { Time.now.to_i }
  let(:now){ Time.at(now_ts) }
  let(:five_minutes_ago){ now - 300 }
  let(:now_range_str) do
    past = (now.to_i - 100) * 1000
    future = (now.to_i + 100) * 1000
    "time > #{ past } AND time < #{ future }"
  end
  let(:never_range_str) do
    range_start = '1'
    range_end = '3'
    "time > #{range_start} AND time < #{range_end}"
  end
  let(:overlap_str) do
    range_start = '1'
    range_end = '2'
    "time > #{range_start} AND time < #{range_end}"
  end

  let(:family){ 'geohash-' + random_key }
  let(:series){ 'user-' + random_key }

  let(:key){ [family, series, now] }
  let(:key_ts){ [family, series, now_ts * 1000] }
  let(:key2){ [family, series, five_minutes_ago] }
  let(:datum){ [*key, 'cloudy', 27.1] }
  let(:datum_null){ [*key2, 'cloudy', nil] }
  let(:extended_datum){ [*key, 'cloudy', "\x0\x1\x2\x3\x4\x5\x6\x7", 27.1] }

  let(:family_series_str) do
    "geohash = '#{family}' AND user = '#{series}'"
  end

  let(:query) do
    <<-SQL
SELECT * FROM #{table_name}
WHERE
  #{family_series_str} AND
  #{now_range_str}
SQL
  end

  let(:no_data_query) do
    <<-SQL
SELECT * FROM #{table_name}
WHERE
  #{family_series_str} AND
  #{never_range_str}
SQL
  end

  let(:overlap_query) do
    <<-SQL
SELECT * FROM #{table_name}
WHERE
  #{family_series_str} AND
  #{overlap_str}
SQL
  end

  let(:describe_table) do
    "DESCRIBE #{table_name}"
  end

  let(:create_table) do
    <<-SQL
CREATE TABLE #{extended_table_name} (
    geohash varchar not null,
    user varchar not null,
    time timestamp not null,
    weather varchar not null,
    frazzle blob not null,
    temperature double,
    PRIMARY KEY(
        (geohash, user, quantum(time, 15, m)),
        geohash, user, time
    )
)
SQL
  end

  let(:stored_datum_expectation) do
    submission = Riak::TimeSeries::Submission.new test_client, table_name
    submission.measurements = [datum]
    expect{ submission.write! }.to_not raise_error
  end

  let(:stored_datum_null_expectation) do
    submission = Riak::TimeSeries::Submission.new test_client, table_name
    submission.measurements = [datum_null]
    expect{ submission.write! }.to_not raise_error
  end

  let(:stored_extended_datum_expectation) do
    submission = Riak::TimeSeries::Submission.new test_client, extended_table_name
    submission.measurements = [extended_datum]
    expect{ submission.write! }.to_not raise_error
  end

  let(:create_extended_table_expectation) do
    query = Riak::TimeSeries::Query.new test_client, create_table
    expect{ query.issue! }.to_not raise_error
    expect(query.results).to be
    expect(query.results).to be_empty
  end

  describe 'create table via query' do
    subject{ Riak::TimeSeries::Query.new test_client, create_table }

    it 'creates a new table without error' do
      expect{ subject.issue! }.to_not raise_error
      expect(subject.results).to be
      expect(subject.results).to be_empty
    end
  end

  describe 'describe table via query' do
    subject{ Riak::TimeSeries::Query.new test_client, describe_table }

    it 'describes a table without error' do
      expect{ subject.issue! }.to_not raise_error
      expect(subject.results).to be
      expect(subject.results).to_not be_empty
      expect(subject.results.columns).to_not be_empty
    end
  end

  describe 'query interface' do
    subject{ Riak::TimeSeries::Query.new test_client, query }
    let(:subject_without_data) do
      Riak::TimeSeries::Query.new test_client, no_data_query
    end
    let(:subject_overlap_error) do
      Riak::TimeSeries::Query.new test_client, overlap_query
    end

    it 'queries data without error' do
      stored_datum_expectation

      expect{ subject.issue! }.to_not raise_error
      expect(subject.results).to be
      expect(subject.results).to_not be_empty
      expect(subject.results.columns).to_not be_empty
    end

    it 'returns an empty response when not finding data' do
      expect{ subject_without_data.issue! }.to_not raise_error
      expect(subject.results).to_not be
    end

    it 'returns an error when query overlaps' do
      expect{ subject_overlap_error.issue! }.
        to raise_error Riak::ProtobuffsErrorResponse
      expect(subject.results).to_not be
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
      expect(result).to_not be_empty
      expect(result.first).to_not be_empty
    end

    it 'retrieves data with a null value without error' do
      stored_datum_null_expectation

      subject.key = key2
      result = nil
      expect{ result = subject.read! }.to_not raise_error
      expect(result).to be
      expect(result).to_not be_empty

      row = result.first
      expect(row).to_not be_empty
      expect(row[4]).to_not be
    end

    it 'attempts retrieval of non-existent data without error' do
      subject.key = [ 'foo', 'bar', now ]
      result = nil
      expect{ result = subject.read! }.to_not raise_error
      expect(result).to_not be
    end
  end

  describe 'single-key delete interface' do
    subject{ Riak::TimeSeries::Deletion.new test_client, table_name }
    let(:test_read){ Riak::TimeSeries::Read.new test_client, table_name }

    it 'deletes data without error' do
      stored_datum_expectation

      test_read.key = key
      expect(test_read.read!).to_not be_empty

      subject.key = key
      expect{ subject.delete! }.to_not raise_error

      expect(test_read.read!).to_not be
    end
  end

  describe 'submission interface' do
    it 'writes data without error' do
      stored_datum_expectation
    end
    it 'writes data with a null value without error' do
      stored_datum_null_expectation
    end
  end

  describe 'list interface' do
    it 'passes listed keys to a block' do
      stored_datum_expectation
      found_expectation = double 'expectation'
      expect(found_expectation).to receive(:found!).once

      lister = Riak::TimeSeries::List.new test_client, table_name

      lister.issue! do |row|
        found_expectation.found! if row.to_a == key_ts
      end
    end

    it 'returns a list of keys without a block' do
      stored_datum_expectation
      found_expectation = double 'expectation'

      lister = Riak::TimeSeries::List.new test_client, table_name

      results = lister.issue!

      expect(results).to include key_ts
    end
  end

  describe 'blob datetype handling' do
    it 'creates a new table with a blob type without error' do
      create_extended_table_expectation
    end

    it 'writes data without error' do
      create_extended_table_expectation
      stored_extended_datum_expectation
    end

    subject{ Riak::TimeSeries::Read.new test_client, extended_table_name }
    it 'returns fetch blob data' do
      create_extended_table_expectation
      stored_extended_datum_expectation

      subject.key = key
      result = nil

      expect{ result = subject.read! }.to_not raise_error
      expect(result).to be
      expect(result).to_not be_empty
      expect(result.first).to_not be_empty

      row = result.first
      expect(row).to_not be_empty
      expect(row[4]).to eq extended_datum[4]
    end
  end
end
