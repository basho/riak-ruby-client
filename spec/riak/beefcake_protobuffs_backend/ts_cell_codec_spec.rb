require 'spec_helper'
require 'bigdecimal'
require 'time'

Riak::Client::BeefcakeProtobuffsBackend.configured?

describe Riak::Client::BeefcakeProtobuffsBackend::TsCellCodec do
  describe 'symmetric serialization' do
    it { is_expected.to symmetric_serialize("hello", varchar_value: "hello")}
    it { is_expected.to symmetric_serialize(5, sint64_value: 5)}
    it { is_expected.to symmetric_serialize(123.45, double_value: 123.45) }
    it do
      subject.convert_timestamp = true
      is_expected.to symmetric_serialize(Time.parse("June 23, 2015 at 9:46:28 EDT"),
                                         timestamp_value: 1_435_067_188_000)
    end
    # GH-274
    it do
      subject.convert_timestamp = true
      ts = 1_459_444_070_103
      t = Time.at(1_459_444_070, 103_000)
      is_expected.to symmetric_serialize(t, timestamp_value: ts)
    end
    it { is_expected.to symmetric_serialize(true, boolean_value: true) }
    it { is_expected.to symmetric_serialize(false, boolean_value: false) }
    it { is_expected.to symmetric_serialize(nil, {}) }
  end

  describe 'serializing values' do
    it do
      is_expected.to serialize(BigDecimal.new("0.1"), double_value: 0.1)
    end

    it 'refuses to serialize big numbers' do
      expect{ subject.cell_for 2**64 }.
        to raise_error Riak::TimeSeriesError::SerializeBigIntegerError
    end

    it 'refuses to serialize complex numbers' do
      expect{ subject.cell_for(Complex(1, 1)) }.
        to raise_error Riak::TimeSeriesError::SerializeComplexNumberError
    end

    it 'refuses to serialize rational numbers' do
      expect{ subject.cell_for(Rational(1, 1)) }.
        to raise_error Riak::TimeSeriesError::SerializeRationalNumberError
    end
  end

  # deserialization is handled by the symmetric cases above
  # describe 'deserializing values'

  describe 'with a collection' do
    let(:not_serialized){ ['hi', 5, 12.34] }
    let(:serialized) do
      [
        Riak::Client::BeefcakeProtobuffsBackend::TsCell.new(varchar_value: 'hi'),
        Riak::Client::BeefcakeProtobuffsBackend::TsCell.new(sint64_value: 5),
        Riak::Client::BeefcakeProtobuffsBackend::TsCell.new(double_value: 12.34)
      ]
    end

    it 'serializes' do
      expect(subject.cells_for(not_serialized)).to eq serialized
    end

    it 'deserializes' do
      expect(subject.scalars_for(serialized)).to eq not_serialized
    end
  end

  RSpec::Matchers.define :symmetric_serialize do |scalar, cell_options|
    match do |codec|
      expect(codec).to(
        serialize(scalar, cell_options)
        .and(deserialize(scalar, cell_options)))
    end

    failure_message do |codec|
      cell = Riak::Client::BeefcakeProtobuffsBackend::TsCell.new cell_options
      deserialized = codec.scalar_for cell
      "expected #{scalar} => #{cell_options} => #{scalar}, got #{scalar} => #{cell.to_hash} => #{deserialized}"
    end

    description do
      "serialize #{scalar.class} #{scalar.inspect} to and from TsCell #{cell_options}"
    end
  end

  RSpec::Matchers.define :serialize do |measure, options|
    match do |actual|
      serialized = actual.cell_for(measure)
      serialized.to_hash == options
    end

    failure_message do |actual|
      serialized = actual.cell_for(measure)
      "expected #{options}, got #{serialized.to_hash}"
    end

    description do
      "serialize #{measure.class} #{measure.inspect} to TsCell #{options}"
    end
  end

  RSpec::Matchers.define :deserialize do |expected, options|

    cell = Riak::Client::BeefcakeProtobuffsBackend::TsCell.new options

    match do |codec|
      deserialized = codec.scalar_for cell
      deserialized == expected
    end

    failure_message do |codec|
      deserialized = codec.scalar_for cell
      "expected TsCell #{options.inspect} to deserialize to #{expected.class} #{expected.inspect}"
    end

    description do
      "deserialize TsCell #{options} to #{expected.class} #{expected.inspect}"
    end
  end
end
