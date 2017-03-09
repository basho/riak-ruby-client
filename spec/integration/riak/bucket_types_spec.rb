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

describe 'Bucket Types', test_client: true, integration: true do
  describe 'nested bucket types API' do
    let(:bucket_type){ test_client.bucket_type 'yokozuna' }

    it 'exposes bucket type properties' do
      expect(props = bucket_type.properties).to be_a Hash
      expect(props[:allow_mult]).to be
    end

    describe 'performing key-value operations' do
      let(:bucket){ bucket_type.bucket(random_key) }
      let(:untyped_bucket){ test_client.bucket bucket.name }

      let(:object) do
        object = bucket.new random_key
        object.data = 'hello'
        object.content_type = 'text/plain'
        object.store
        object
      end

      let(:untyped_object) do
        untyped_object = untyped_bucket.new object.key
        untyped_object.data = 'oooops'
        untyped_object.content_type = 'text/plain'
        untyped_object.store
        untyped_object
      end

      it 'initializes with a bucket type' do
        o = bucket.new 'lawnmower'
        o.data = 'reel'
        o.content_type = 'text/plain'
        o.store

        expect(bucket.get('lawnmower').data).to eq o.data
        expect(bucket.exists?('lawnmower')).to be
      end

      describe 'loading and modifying a RObject' do
        it "doesn't modify objects in other buckets" do
          expect(o = bucket.get(object.key)).to be
          o.data = 'updated'
          o.store
          o.reload

          expect(o.data).to eq 'updated'

          expect{ untyped_bucket.get(object.key)}.to raise_error(/not found/)

          expect(o3 = bucket.get(object.key)).to be
          expect(o3.data).to eq o.data
        end

        it "doesn't delete objects in other buckets'" do
          expect{ untyped_object.reload }.to_not raise_error

          expect(o = bucket.get(object.key)).to be
          o.delete

          expect{ untyped_object.reload }.to_not raise_error
        end
      end

      it 'only retrieves with a bucket type' do
        expect(bucket.get(object.key).data).to eq object.data
        expect{ untyped_bucket.get object.key }.to raise_error /not_found/
      end

      it 'reloads with a bucket type' do
        expect{ object.reload }.to_not raise_error
        expect(object.data).to eq 'hello'
      end

      it 'lists keys only for the type' do
        expect(untyped_bucket).to be # ensure existence
        expect(object).to be

        expect(untyped_bucket.keys).to be_empty
        expect(bucket.keys).to include object.key
      end

      it 'keeps the bucket type attached to value objects' do
        expect(bucket.get(object.key).bucket).to eq bucket
        expect(bucket.get(object.key).bucket.type).to eq bucket_type
      end

      describe 'deletion' do
        it 'self-deletes with a bucket type' do
          expect(untyped_object).to be # ensure existence

          expect(object.delete).to be
          expect{ object.reload }.to raise_error /not_found/
          expect(untyped_object).to be
          expect{ untyped_object.reload }.to_not raise_error
        end

        it 'deletes from the typed bucket' do
          expect(untyped_object).to be # ensure existence

          expect(bucket.delete object.key).to be
          expect{ object.reload }.to raise_error /not_found/
          expect{ untyped_object.reload }.to_not raise_error
        end
      end

      it 'multigets keys' do
        results = bucket.get_many [object.key]
        expect(results[object.key]).to be
        expect(results[object.key].data).to eq object.data
      end

      describe 'secondary indexes' do
        it 'finds the correct object with a SecondaryIndex instance' do
          expect(untyped_object).to be
          q = Riak::SecondaryIndex.new bucket, '$key', object.key

          expect(q.keys).to include object.key
          candidate = q.values.first
          expect(candidate.data).to eq object.data
        end
      end

      describe 'map-reduce' do
        let(:mapred) do
          Riak::MapReduce.new(test_client) do |mr|
            mr.map 'function(obj){return [obj.values[0].data];}', keep: true
          end
        end

        it 'map-reduces correctly with a typed bucket' do
          expect(object).to be
          expect(untyped_object).to be

          mapred.add bucket
          result = mapred.run

          expect(result).to include object.data
          expect(result).to_not include untyped_object.data
        end

        it 'map-reduces correctly with a robject in a typed bucket' do
          expect(object).to be
          expect(untyped_object).to be

          mapred.add object
          result = mapred.run

          expect(result).to include object.data
          expect(result).to_not include untyped_object.data
        end
      end
    end

    describe 'manipulating bucket properties' do
      let(:bucket_type){ test_client.bucket_type 'yokozuna' }
      let(:bucket){ bucket_type.bucket random_key }
      let(:untyped_bucket){ test_client.bucket bucket.name }

      it 'allows reading and writing bucket properties' do
        expect(test_client.get_bucket_props(bucket, type: 'yokozuna')['notfound_ok']).to be
        expect(test_client.get_bucket_props(untyped_bucket)['notfound_ok']).to be

        # test setting
        expect{ bucket.props = {'notfound_ok' => false} }.to_not raise_error

        # make sure setting doesn't leak to untyped bucket
        expect(test_client.get_bucket_props(bucket, type: 'yokozuna')['notfound_ok']).to_not be
        expect(test_client.get_bucket_props(untyped_bucket)['notfound_ok']).to be

        # add canary setting on untyped bucket
        expect{ untyped_bucket.props = { 'n_val' => 1} }.to_not raise_error

        # make sure canary setting doesn't leak to typed bucket
        expect(test_client.get_bucket_props(bucket, type: 'yokozuna')['n_val']).to_not eq 1
        expect(test_client.get_bucket_props(untyped_bucket)['n_val']).to eq 1

        # test clearing
        expect{ bucket.clear_props }.to_not raise_error

        # make sure clearing doesn't leak to canary setting on untyped bucket
        expect(test_client.get_bucket_props(bucket, type: 'yokozuna')['notfound_ok']).to be
        expect(test_client.get_bucket_props(untyped_bucket)['n_val']).to eq 1
      end
    end

    describe 'manipulating bucket type properties' do
      let(:bucket_type){ test_client.bucket_type 'plain' }
      let(:other_bucket_type){ test_client.bucket_type 'no_siblings' }

      it 'allows reading and writing bucket properties' do
        expect(test_client.get_bucket_type_props(bucket_type)['notfound_ok']).to be
        expect(test_client.get_bucket_type_props(other_bucket_type)['notfound_ok']).to be

        # test setting
        expect{ bucket_type.props = {'notfound_ok' => false} }.to_not raise_error

        # make sure setting doesn't leak
        expect(test_client.get_bucket_type_props(bucket_type)['notfound_ok']).to_not be
        expect(test_client.get_bucket_type_props(other_bucket_type)['notfound_ok']).to be

        # test clearing
        expect{ bucket_type.clear_props }.to_not raise_error

        expect(test_client.get_bucket_type_props(bucket_type)['notfound_ok']).to be
      end
    end

    describe 'performing CRDT operations' do
      let(:bucket_type){ test_client.bucket_type 'other_counters' }
      let(:bucket){ bucket_type.bucket random_key }
      let(:counter){ Riak::Crdt::Counter.new bucket, random_key }

      let(:untyped_bucket){ test_client.bucket bucket.name }
      let(:untyped_counter){ Riak::Crdt::Counter.new untyped_bucket, random_key }

      it 'overrides default bucket types for CRDTs' do
        expect(untyped_counter.value).to eq 0
        expect(untyped_counter.bucket_type).to eq Riak::Crdt::DEFAULT_BUCKET_TYPES[:counter]

        untyped_counter.increment
        counter.reload

        expect(counter.value).to eq 0
        expect(counter.bucket_type).to eq 'other_counters'
      end
    end
  end

  describe 'option-based bucket types API' do
    let(:bucket){ random_bucket 'bucket_type_spec' }

    describe 'performing key-value operations' do
      # for the sake of having a non-default one, not search
      let(:bucket_type){ 'yokozuna' }
      let(:object) do
        object = bucket.new random_key
        object.data = 'hello'
        object.content_type = 'text/plain'
        object.store type: bucket_type
        object
      end

      it 'only retrieves with a bucket type' do
        expect{ bucket.get object.key, type: bucket_type }.to_not raise_error
        expect{ bucket.get object.key }.to raise_error /not_found/
      end

      it 'deletes from the bucket only with a bucket type' do
        expect(bucket.delete object.key).to eq true
        expect{ bucket.get object.key, type: bucket_type }.to_not raise_error

        expect{ bucket.delete object.key, type: bucket_type }.to_not raise_error
        expect{ bucket.get object.key, type: bucket_type }.to raise_error /not_found/
      end

      it 'self-deletes only with a bucket type' do
        expect(object.delete).to be
        expect{ object.reload type: bucket_type }.to_not raise_error

        expect(object.delete type: bucket_type).to be
        expect{ object.reload type: bucket_type }.to raise_error /not_found/
      end
    end

    describe 'performing CRDT set operations' do
      let(:bucket_type){ Riak::Crdt::DEFAULT_BUCKET_TYPES[:set] }
      let(:set) do
        set = Riak::Crdt::Set.new bucket, random_key
        set.add random_key
        set
      end

      it 'retrieves the set blob via key-value using a bucket type' do
        expect{ bucket.get set.key }.to raise_error /not_found/
        expect(bucket.get set.key, type: bucket_type).to be
      end

      it 'deletes the set blob through the bucket type' do
        expect(bucket.delete set.key).to be
        expect{ bucket.get set.key, type: bucket_type }.to_not raise_error

        expect(bucket.delete set.key, type: bucket_type).to be
        expect{ bucket.get set.key, type: bucket_type }.to raise_error /not_found/
      end
    end

    describe 'performing CRDT Grow Only Set operations' do
      before(:each) do
        ensure_datatype_exists :gset
      end

      let(:bucket_type){ Riak::Crdt::DEFAULT_BUCKET_TYPES[:gset] }
      let(:gset) do
        gset = Riak::Crdt::GrowOnlySet.new bucket, random_key
        gset.add random_key
        gset
      end

      it 'retrieves the grow only set blob via key-value using a bucket type' do
        expect{ bucket.get gset.key }.to raise_error /not_found/
        expect(bucket.get gset.key, type: bucket_type).to be
      end

      it 'deletes the grow only set blob through the bucket type' do
        expect(bucket.delete gset.key).to be
        expect{ bucket.get gset.key, type: bucket_type }.to_not raise_error

        expect(bucket.delete gset.key, type: bucket_type).to be
        expect{ bucket.get gset.key, type: bucket_type }.to raise_error /not_found/
      end
    end

    describe 'performing CRDT HLL operations', hll: true do
      before(:all) do
        ensure_datatype_exists :hll
      end

      let(:bucket_type){ Riak::Crdt::DEFAULT_BUCKET_TYPES[:hll] }
      let(:hll) do
        hyper_log_log = Riak::Crdt::HyperLogLog.new bucket, random_key, bucket_type
        hyper_log_log.add random_key
        hyper_log_log
      end
      let(:empty_hll) do
        Riak::Crdt::HyperLogLog.new bucket, random_key, bucket_type
      end

      it 'defaults to 0 for a new key' do
        expect(empty_hll.cardinality).to eq 0
      end

      it 'retrieves the HLL blob via key-value using a bucket type' do
        expect{ bucket.get hll.key }.to raise_error /not_found/
        expect(bucket.get hll.key, type: bucket_type).to be
      end

      it 'deletes the HLL blob through the bucket type' do
        expect(bucket.delete hll.key).to be
        expect{ bucket.get hll.key, type: bucket_type }.to_not raise_error

        expect(bucket.delete hll.key, type: bucket_type).to be
        expect{ bucket.get hll.key, type: bucket_type }.to raise_error /not_found/
      end

      it 'defaults to 14 for hll_precision' do
        bt = test_client.bucket_type bucket_type
        expect(props = bt.properties).to be_a Hash
        expect(props[:hll_precision]).to eq 14
      end

      it 'allows setting hll_precision' do
        bt = test_client.bucket_type bucket_type
        expect{ bt.properties[:hll_precision] = 14 }.to_not raise_error
      end
    end
  end
end
