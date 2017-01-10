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
require 'riak/bucket_properties'

describe Riak::BucketProperties, test_client: true, integration: true do
  describe 'Bucket Properties objects' do
    let(:bucket){ random_bucket 'props' }
    subject{ described_class.new bucket }

    let(:other_bucket) do
      random_bucket('props-other').tap do |b|
        p = described_class.new b
        p['r'] = 1
        p.store
      end
    end
    let(:other_props){ described_class.new other_bucket }

    before(:example) do
      bucket.clear_props
      subject.reload
    end

    it 'is initializable with a bucket' do
      expect{ described_class.new bucket }.to_not raise_error
    end

    it 'works like a hash' do
      expect(subject['r']).to eq 'quorum'
      expect{ subject['r'] = 1 }.to_not raise_error
      subject.store
      subject.reload

      expect(subject['r']).to eq 1
    end

    it 'can be merged from a hash' do
      bulk_props = { r: 1, w: 1, dw: 1 }
      expect{ subject.merge! bulk_props }.to_not raise_error
      subject.store
      subject.reload

      expect(subject['r']).to eq 1
      expect(subject['w']).to eq 1
      expect(subject['dw']).to eq 1
    end

    it 'can be merged from a bucket properties object' do
      expect(other_props['r']).to eq 1
      expect(subject['r']).to eq 'quorum'

      expect{ subject.merge! other_props }.to_not raise_error
      subject.store
      subject.reload

      expect(subject['r']).to eq 1
    end

    let(:modfun){ { 'mod' => 'validate_json', 'fun' => 'validate' } }

    it 'works with composite/modfun properties' do
      expect{ subject['precommit'] = modfun }.to_not raise_error

      subject.store
      subject.reload

      expect(subject['precommit']).to eq [modfun]
    end
  end
end
