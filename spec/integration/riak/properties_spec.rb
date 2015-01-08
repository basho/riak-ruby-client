describe 'Bucket and Bucket Type Properties', integration: true do
  
  describe 'Bucket Properties objects' do
    it 'is accessible from a bucket' do
      expect(props = bucket.props).to be_a Riak::BucketProperties
    end

    it 'works like a hash' do
      expect(props['r']).to eq 'quorum'
      expect{ props['r'] = 1 }.to_not raise_error
      props.store
      props.reload

      expect(props['r']).to eq 1
    end

    it 'can be merged from a hash' do
      bulk_props = { r: 1, w: 1, dw: 1 }
      expect{ props.merge! bulk_props }.to_not raise_error
      props.store
      props.reload

      expect(props.r).to eq 1
      expect(props.w).to eq 1
      expect(props.dw).to eq 1
    end

    it 'can be merged from a bucket properties object' do
      other = other_bucket.props
      expect(other.r).to eq 1
      expect(props.r).to eq 'quorum'

      expect{ props.merge! other }.to_not raise_error
      props.store
      props.reload

      expect(props.r).to eq 1
    end
  end
end
