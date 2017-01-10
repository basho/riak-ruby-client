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

describe Riak::TimeSeries::List do
  subject { described_class.new client, table_name }
  let(:table_name){ 'GeoCheckin' }
  let(:client){ instance_double('Riak::Client') }
  let(:key){ double 'key' }
  let(:backend) do
    instance_double('Riak::Client::BeefcakeProtobuffsBackend').tap do |be|
      allow(client).to receive(:backend).and_yield be
      allow(client).to receive(:convert_timestamp).and_return(true)
    end
  end
  let(:operator) do
    Riak::Client::BeefcakeProtobuffsBackend.configured?
    instance_double(
      'Riak::Client::BeefcakeProtobuffsBackend::TimeSeriesListOperator'
    ).tap do |op|
      allow(backend).to receive(:time_series_list_operator).
                         and_return(op)
    end
  end

  let(:list_results) do
    Riak::TimeSeries::Collection.new.tap do |buf|
      %w{family series timestamp}
    end
  end

  it 'initializes with client and table name' do
    expect{ described_class.new client, table_name }.to_not raise_error
    expect{ described_class.new client }.to raise_error ArgumentError
  end

  it 'passes a block to the operator' do
    streamer = proc { double 'block contents' }

    expect(operator).to receive(:list).with(table_name, streamer, timeout: nil)

    subject.issue! &streamer
  end

  it 'returns a list of results' do
    expect(operator).to receive(:list).
                         with(table_name, nil, timeout: nil).
                         and_return(list_results)

    expect(subject.issue!).to eq list_results
    expect(subject.results).to eq list_results
  end
end
