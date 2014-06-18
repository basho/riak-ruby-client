describe 'Bucket Types', test_client: true, integration: true do
  describe 'performing key-value operations' do
    it 'stores objects into a bucket type'
    it 'retrieves objects from a bucket type'
    it 'does not retrieve without a bucket type'
  end

  describe 'performing CRDT set operations' do
    it 'stores the set into a bucket type'
    it 'retrieves the set blob via key-value using a bucket type'
    it 'deletes the set blob through the bucket type'
  end
end
