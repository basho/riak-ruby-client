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
require 'riak/bucket_type_properties'

describe Riak::BucketTypeProperties do
  let(:client){ instance_double 'Riak::Client' }
  let(:backend) do
    instance_double('Riak::Client::BeefcakeProtobuffsBackend').tap do |be|
      allow(client).to receive(:backend).and_yield be
    end
  end

  let(:props_operator) do
    Riak::Client::BeefcakeProtobuffsBackend.configured?
    instance_double(
      'Riak::Client::BeefcakeProtobuffsBackend::BucketTypePropertiesOperator'
    ).tap do |po|
      allow(backend).to receive(:bucket_type_properties_operator).
        and_return(po)
    end
  end

  let(:bucket_type) do
    instance_double('Riak::BucketType').tap do |b|
      allow(b).to receive(:client).and_return(client)
    end
  end

  let(:other_bucket_type) do
    instance_double('Riak::BucketType').tap do |b|
      allow(b).to receive(:client).and_return(client)
    end
  end

  let(:index_name){ 'index_name' }

  let(:index) do
    instance_double('Riak::Search::Index').tap do |i|
      allow(i).to receive(:name).and_return(index_name)
      allow(i).to receive(:is_a?).with(Riak::Search::Index).and_return(true)
    end
  end

  subject{ described_class.new bucket_type }

  it 'is initialized with a bucket type' do
    p = nil
    expect{ p = described_class.new bucket_type }.to_not raise_error
    expect(p.client).to eq client
    expect(p.bucket_type).to eq bucket_type
  end

  it 'provides hash-like access to properties' do
    expect(props_operator).to receive(:get).
      with(bucket_type).
      and_return('allow_mult' => true)

    expect(subject['allow_mult']).to be

    subject['allow_mult'] = false

    expect(props_operator).to receive(:put).
      with(bucket_type, hash_including('allow_mult' => false))

    subject.store
  end

  it 'unwraps index objects into names' do
    expect(props_operator).to receive(:get).
      with(bucket_type).
      and_return('allow_mult' => true)

    expect{ subject['search_index'] = index }.to_not raise_error

    expect(subject['search_index']).to eq index_name
  end

  it 'merges properties from hashes' do
    expect(props_operator).to receive(:get).
      with(bucket_type).
      and_return('allow_mult' => true)

    expect(subject['allow_mult']).to be

    property_hash = { 'allow_mult' => false }
    expect{ subject.merge! property_hash }.to_not raise_error

    expect(props_operator).to receive(:put).
      with(bucket_type, hash_including('allow_mult' => false))

    subject.store
  end

  it 'merges properties from other bucket type properties objects' do
    expect(props_operator).to receive(:get).
      with(bucket_type).
      and_return('allow_mult' => true)

    expect(subject['allow_mult']).to be

    other_props = described_class.new other_bucket_type
    other_props.
      instance_variable_set :@cached_props, { 'allow_mult' => false}

    expect{ subject.merge! other_props }.to_not raise_error

    expect(props_operator).to receive(:put).
      with(bucket_type, hash_including('allow_mult' => false))

    subject.store
  end

  it 'reloads' do
    expect(props_operator).to receive(:get).
      with(bucket_type).
      and_return('allow_mult' => true)

    expect(subject['allow_mult']).to be

    expect(props_operator).to receive(:get).
      with(bucket_type).
      and_return('allow_mult' => false)

    expect{ subject.reload }.to_not raise_error

    expect(subject['allow_mult']).to_not be
  end
end
