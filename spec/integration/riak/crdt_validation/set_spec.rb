require 'spec_helper'
require 'riak'

describe 'CRDT set validation', integration: true, test_client: true do
  let(:bucket){ random_bucket 'crdt_validation' }
  let(:set){ Riak::Crdt::Set.new bucket, random_key }
  
  it 'should allow removal of recently-added set entries during batch mode' do
    expect do
      set.batch do |s|
        s.add 'X'
        s.add 'Y'
        s.add 'Z'
        s.remove 'Y'
      end
    end.to_not raise_error
    
    set2 = Riak::Crdt::Set.new bucket, set.key
    expect(set2.members).to eq ::Set.new(['X', 'Z'])
  end
  
  it 'should allow removal of non-members with context' do
    set.batch do |s|
      s.add 'X'
      s.add 'Y'
    end
    
    set.reload
    
    expect{ set.remove 'bogus' }.to_not raise_error
    
    set2 = Riak::Crdt::Set.new bucket, set.key
    expect(set2.members).to eq ::Set.new(%w{X Y})
  end

  it 'should allow adding of duplicate members' do
    set.batch do |s|
      s.add 'X'
      s.add 'Y'
    end
    
    set.reload
    
    expect{ set.add 'X' }.to_not raise_error

    set2 = Riak::Crdt::Set.new bucket, set.key
    expect(set2.members).to eq ::Set.new(%w{X Y})
  end

  it 'should no-op adding then removing a duplicate member' do
    set.batch do |s|
      s.add 'X'
      s.add 'Y'
    end

    set.reload
    expect(set.members).to eq ::Set.new(%w{X Y})

    expect do
      set.batch do |s|
        s.add 'X'
        s.remove 'X'
      end
    end.to_not raise_error

    set2 = Riak::Crdt::Set.new bucket, set.key
    expect(set2.members).to eq ::Set.new(%w{X Y})
  end

  it 'should no-op removing then re-adding a set member' do
    set.batch do |s|
      s.add 'X'
      s.add 'Y'
    end

    set.reload
    expect(set.members).to eq ::Set.new(%w{X Y})

    expect do
      set.batch do |s|
        s.remove 'X'
        s.add 'X'
      end
    end.to_not raise_error

    set2 = Riak::Crdt::Set.new bucket, set.key
    expect(set2.members).to eq ::Set.new(%w{X Y})
  end
end
