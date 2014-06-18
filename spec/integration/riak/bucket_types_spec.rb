require 'spec_helper'
require 'riak'

describe 'Bucket Types', test_client: true, integration: true do
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
    it 'stores the set into a bucket type'
    it 'retrieves the set blob via key-value using a bucket type'
    it 'deletes the set blob through the bucket type'
  end
end
