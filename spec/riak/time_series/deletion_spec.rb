require 'spec_helper'

describe Riak::TimeSeries::Deletion do
  subject{ described_class.new client, table_name }
  let(:table_name){ 'GeoCheckins' }
  let(:client){ instance_double('Riak::Client') }
  let(:key){ double 'key' }
  let(:backend) do
    instance_double('Riak::Client::BeefcakeProtobuffsBackend').tap do |be|
      allow(client).to receive(:backend).and_yield be
    end
  end
  let(:operator) do
    Riak::Client::BeefcakeProtobuffsBackend.configured?
    instance_double(
      'Riak::Client::BeefcakeProtobuffsBackend::TimeSeriesDeleteOperator'
    ).tap do |op|
      allow(backend).to receive(:time_series_delete_operator).
                         and_return(op)
    end
  end

  it 'initializes with client and table name' do
    expect{ described_class.new client, table_name }.to_not raise_error
    expect{ described_class.new client }.to raise_error ArgumentError
  end

  it 'passes keys to delete to a delete operator' do
    expect{ subject.key = key }.to_not raise_error
    expect(operator).to receive(:delete).with(table_name, key, Hash.new)
    expect{ subject.delete! }.to_not raise_error
  end
end
