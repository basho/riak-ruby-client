require 'spec_helper'
require 'riak'

describe "CRDTs", integration: true, test_client: true do
  let(:bucket) { random_bucket }

  describe 'Riak-assigned names' do
    describe 'an anonymous counter' do
      subject { Riak::Crdt::Counter.new bucket, nil }
      it 'accepts a Riak-assigned name' do
        subject.increment
        expect(subject.key).to be
        expect(subject.value).to eq 1
      end
    end

    describe 'an anonymous set' do
      subject { Riak::Crdt::Set.new bucket, nil }
      it 'accepts a Riak-assigned name' do
        subject.add 'sandwich'
        expect(subject.key).to be
        expect(subject).to include 'sandwich'
      end
    end

    describe 'an anonymous map' do
      subject { Riak::Crdt::Map.new bucket, nil }
      it 'accepts a Riak-assigned name' do
        subject.registers['coat_pattern'] = 'tabby'
        expect(subject.key).to be
        expect(subject.registers['coat_pattern']).to eq 'tabby'
      end
    end
  end

  describe 'counters' do
    subject { Riak::Crdt::Counter.new bucket, random_key }
    it 'allows straightforward counter ops' do
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

    it 'allows batched counter ops' do
      start = subject.value
      subject.batch do |s|
        s.increment
        s.increment 2
        s.increment
        s.increment
      end
      expect(subject.value).to eq(start + 5)
    end

    it 'asks for and accepts a returned body by default' do
      other = Riak::Crdt::Counter.new subject.bucket, subject.key

      start = subject.value

      expect(subject.value).to eq start

      other.increment 10

      subject.increment 1

      expect(subject.dirty?).to_not be
      expect(subject.value).to eq(start + 10 + 1)
    end
  end
  describe 'sets' do

    subject { Riak::Crdt::Set.new bucket, random_key }

    it 'allows straightforward set ops' do
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

    it 'lets Riak silently accept removals after reload' do
      addition = random_key
      subject.add addition

      other = Riak::Crdt::Set.new subject.bucket, subject.key
      expect{ other.remove addition }.to raise_error(Riak::CrdtError::SetRemovalWithoutContextError)
      other.reload
      expect{ other.remove addition }.to_not raise_error
      other.reload
      expect{ other.remove 'an element not in the set' }.to_not raise_error
    end

    it 'allows batched set ops' do
      subject.add 'zero'
      subject.reload

      subject.batch do |s|
        s.add 'first'
        s.remove 'zero'
      end

      expect(subject.members.to_a).to eq %w{first}
    end

    it 'asks for and accepts a returned body by default' do
      other = Riak::Crdt::Set.new subject.bucket, subject.key

      expect(subject.include? 'coffee').to_not be
      expect(other.include? 'coffee').to_not be

      other.add 'coffee'
      subject.add 'tea'

      expect(subject.dirty?).to_not be

      expect(other.include? 'coffee').to be
      expect(subject.include? 'coffee').to be
    end
  end

  describe 'maps' do
    subject { Riak::Crdt::Map.new bucket, random_key }

    it 'allows straightforward map ops' do
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

      subject.counters['hits'].increment
      expect(subject.counters['hits'].value).to eq 1

      subject.flags['yes'] = true
      expect(subject.flags['yes']).to eq true

      expect do
        subject.registers.delete 'first'
        subject.sets.delete 'arnold'
        subject.maps.delete 'first'
        subject.counters.delete 'hits'
        subject.flags.delete 'yes'
      end.to_not raise_error
    end

    it 'allows batched map ops' do
      subject.batch do |s|
        s.registers['condiment'] = 'ketchup'
        s.counters['banana'].increment
      end

      expect(subject.registers['condiment']).to eq 'ketchup'
      expect(subject.counters['banana'].value).to eq 1
    end

    it 'asks for and accepts a returned body by default' do
      other = Riak::Crdt::Map.new subject.bucket, subject.key

      expect(subject.sets['bees'].include? 'honey').to_not be
      expect(other.sets['bees'].include? 'honey').to_not be

      other.sets['bees'].add 'honey'
      subject.counters['stings'].increment

      expect(subject.dirty?).to_not be

      expect(other.sets['bees'].include? 'honey').to be
      expect(subject.sets['bees'].include? 'honey').to be
    end

    describe 'containing a map' do
      it 'bubbles straightforward map ops up' do
        street_map = subject.maps['street']

        street_map.registers['bird'] = 'avenue'
        street_map.flags['traffic_light'] = false

        expect(subject.maps['street'])
      end

      it 'includes inner-map ops in the outer-map batch' do
        subject.batch do |m|
          m.maps['road'].counters['speedbumps'].increment 4
          m.maps['road'].sets['signs'].add 'yield'
        end

        expect(subject.maps['road'].counters['speedbumps'].value).to eq 4
        expect(subject.maps['road'].sets['signs'].include? 'yield').to be
      end
    end

    describe 'containing a register' do
      it 'bubbles straightforward register ops up' do
        subject.registers['hkey_local_machine'] = 'registry'

        expect(subject.registers['hkey_local_machine']).to eq 'registry'
      end

      it "doesn't error on an unset register" do
        expect{ subject.registers['unset'] }.to_not raise_error
        expect(subject.registers['other_unset']).to_not be
      end
    end

    describe 'containing a flag' do
      it 'bubbles straightforward flag ops up' do
        subject.flags['enable_magic'] = true

        expect(subject.flags['enable_magic']).to be
      end

      it "doesn't error on an unset flag" do
        expect{ subject.flags['unset'] }.to_not raise_error
        expect(subject.flags['other_unset']).to_not be
      end
    end
  end
end
