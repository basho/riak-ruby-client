require 'spec_helper'
require 'riak'

describe 'Bucket Types', test_client: true, integration: true do

  describe 'nested bucket types API' do
    describe 'performing key-value operations' do
      let(:bucket_type){ test_client.bucket_type 'yokozuna' }
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
        expect(test_client.get_bucket_props(bucket, type: 'yokozuna')['last_write_wins']).to_not be
        expect(test_client.get_bucket_props(untyped_bucket)['last_write_wins']).to_not be
        
        # test setting
        expect{ bucket.props = {'last_write_wins' => true} }.to_not raise_error

        # make sure setting doesn't leak to untyped bucket
        # use on-bucket props method to test accessor
        expect(bucket.props['last_write_wins']).to be
        expect(untyped_bucket.props['last_write_wins']).to_not be

        # add canary setting on untyped bucket
        expect{ untyped_bucket.props = { 'n_val' => 1} }.to_not raise_error

        # make sure canary setting doesn't leak to typed bucket
        expect(test_client.get_bucket_props(bucket, type: 'yokozuna')['n_val']).to_not eq 1
        expect(test_client.get_bucket_props(untyped_bucket)['n_val']).to eq 1

        # test clearing
        expect{ bucket.clear_props }.to_not raise_error

        # make sure clearing doesn't leak to canary setting on untyped bucket 
        expect(test_client.get_bucket_props(bucket, type: 'yokozuna')['last_write_wins']).to_not be
        expect(test_client.get_bucket_props(untyped_bucket)['n_val']).to eq 1
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
  end
end
