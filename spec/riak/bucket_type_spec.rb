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
require 'riak/bucket_type'

describe Riak::BucketType do
  let(:client){ Riak::Client.allocate }
  let(:name){ 'bucket_type_spec' }
  let(:backend) do
    double('Backend').tap do |backend|
      allow(client).to receive(:backend).and_yield(backend)
    end
  end

  subject{ described_class.new client, name }

  it 'is created with a client and name' do
    expect{ described_class.new client, name }.to_not raise_error
  end

  it 'returns a typed bucket' do
    typed_bucket = subject.bucket 'empanadas'
    expect(typed_bucket).to be_a Riak::Bucket
    expect(typed_bucket).to be_a Riak::BucketTyped::Bucket
    expect(typed_bucket.name).to eq 'empanadas'
    expect(typed_bucket.type).to eq subject
  end

  describe 'equality' do
    let(:same){ described_class.new client, name }
    let(:different_client){ described_class.new Riak::Client.allocate, name }
    let(:different_name){ described_class.new client, 'different name' }
    it { is_expected.to eq same }
    it { is_expected.to_not eq different_client }
    it { is_expected.to_not eq different_name }
  end

  describe 'properties' do
    let(:props_expectation){ expect(backend).to receive(:get_bucket_type_props).with(subject) }

    it 'is queryable' do
      props_expectation.and_return(allow_mult: true)
      expect(props = subject.properties).to be_a Hash
      expect(props[:allow_mult]).to be
    end

    it 'asks for data type' do
      props_expectation.and_return(datatype: 'set')
      expect(subject.data_type_class).to eq Riak::Crdt::Set
    end

    it 'provides-hll-precision' do
      props_expectation.and_return(hll_precision: 14)
      expect(props = subject.properties).to be_a Hash
      expect(props[:hll_precision]).to be
    end
  end
end
