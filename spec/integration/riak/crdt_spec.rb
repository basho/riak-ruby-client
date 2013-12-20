require 'spec_helper'
require 'riak'

describe "CRDTs", integration: true, test_client: true do
  let(:bucket) { random_bucket }

  describe 'configuration' do
    it "should allow default bucket-types to be configured for each data type" do
      expect(Riak::Crdt::Set.new(bucket, 'set').bucket_type).to eq 'sets'
      
      Riak::Crdt::DEFAULT_BUCKET_TYPES[:set] = 'new_set_default'
      expect(Riak::Crdt::Set.new(bucket, 'set').bucket_type).to eq 'new_set_default'

      Riak::Crdt::DEFAULT_BUCKET_TYPES[:set] = 'sets'
      expect(Riak::Crdt::Set.new(bucket, 'set').bucket_type).to eq 'sets'
    end
    
    it "should allow override bucket-types for instances" do
      expect(Riak::Crdt::Set.new(bucket, 'set', 'other_bucket_type').bucket_type).to eq 'other_bucket_type'
    end
  end
  
  describe 'counters' do
    subject { Riak::Crdt::Counter.new bucket, random_key }
    it 'should allow straightforward counter ops' do
      start = subject.value
      subject.increment
      expect(subject.value).to eq(start + 1)
      subject.increment
      expect(subject.value).to eq(start + 2)
      subject.increment -1
      expect(subject.value).to eq(start + 1)
      subject.decrement
      expect(subject.value).to eq(start)
    end
    
    it 'should allow batched counter ops' do
      start = subject.value
      subject.batch do |s|
        s.increment
        s.increment 2
        s.increment
        s.increment
      end
      expect(subject.value).to eq(start + 5)
    end
  end
  describe 'sets' do

    subject { Riak::Crdt::Set.new bucket, random_key }
    
    it 'should allow straightforward set ops' do
      start = subject.members
      addition = random_key

      subject.add addition
      expect(subject.include? addition).to be
      expect(subject.members).to include(addition)

      subject.remove addition
      expect(subject.include? addition).to_not be
      expect(subject.members).to_not include(addition)
      expect(subject.members).to eq(start)
    end
    
    it 'should allow batched set ops' do
      subject.add 'zero'
      subject.batch do |s|
        s.add 'first'
        s.remove 'zero'
      end

      expect(subject.members.to_a).to eq %w{first}
    end
  end
  describe 'maps' do
    subject { Riak::Crdt::Map.new bucket, random_key }
    
    it 'should allow straightforward map ops' do
      subject.registers['first'] = 'hello'
      expect(subject.registers['first']).to eq('hello')

      subject.sets['arnold'].add 'commando'
      subject.sets['arnold'].add 'terminator'
      expect(subject.sets['arnold'].members).to include('commando')
      subject.sets['arnold'].remove 'commando'
      expect(subject.sets['arnold'].members).to_not include('commando')
      expect(subject.sets['arnold'].members).to include('terminator')

      subject.maps['first'].registers['second'] = 'good evening'
      subject.maps['first'].maps['third'].counters['fourth'].increment

      expect(subject.maps['first'].registers['second']).to eq('good evening')
      expect(subject.maps['first'].maps['third'].counters['fourth'].value).to eq(1)
    end
    
    it 'should allow batched map ops' do
      subject.batch do |s|
        s.registers['condiment'] = 'ketchup'
        s.counters['banana'].increment
      end

      expect(subject.registers['condiment']).to eq 'ketchup'
      expect(subject.counters['banana'].value).to eq 1
    end
    
    describe 'containing a map' do
      it 'should bubble straightforward map ops up' do
        street_map = subject.maps['street']

        street_map.registers['bird'] = 'avenue'
        street_map.flags['traffic_light'] = false

        expect(subject.maps['street'])
      end
      
      it 'should include inner-map ops in the outer-map batch' do
        subject.batch do |m|
          m.maps['road'].counters['speedbumps'].increment 4
          m.maps['road'].sets['signs'].add 'yield'
        end

        expect(subject.maps['road'].counters['speedbumps'].value).to eq 4
        expect(subject.maps['road'].sets['signs'].include? 'yield').to be
      end
    end

    describe 'containing a register' do
      it 'should bubble straightforward register ops up' do
        subject.registers['hkey_local_machine'] = 'registry'

        expect(subject.registers['hkey_local_machine']).to eq 'registry'
      end
    end

    describe 'containing a flag' do
      it 'should bubble straightforward flag ops up' do
        subject.flags['enable_magic'] = true

        expect(subject.flags['enable_magic']).to be
      end
    end
  end
end
