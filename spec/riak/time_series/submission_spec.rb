require 'spec_helper'

describe Riak::TimeSeries::Submission do
  subject{ described_class.new client, table_name }
  let(:table_name){ 'GeoCheckin' }
  let(:client){ instance_double('Riak::Client') }
  let(:measurements){ double 'measurements' }
  let(:backend) do
    instance_double('Riak::Client::BeefcakeProtobuffsBackend').tap do |be|
      allow(client).to receive(:backend).and_yield be
    end
  end
  let(:operator) do
    Riak::Client::BeefcakeProtobuffsBackend.configured?
    instance_double(
      'Riak::Client::BeefcakeProtobuffsBackend::TimeSeriesPutOperator'
    ).tap do |po|
      allow(backend).to receive(:time_series_put_operator).
                         and_return(po)
    end
  end

  it 'initializes with client and table name' do
    expect{ described_class.new client, table_name }.to_not raise_error
    expect{ described_class.new client }.to raise_error ArgumentError
  end

  it 'passes measurements to a put operator' do
    expect{ subject.measurements = measurements }.to_not raise_error

    expect(operator).to receive(:put).with(table_name, measurements)

    expect{ subject.write! }.to_not raise_error
  end
end
