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

describe Riak::Crdt::TypedCollection do
  let(:parent){ double 'parent' }
  let(:operation){ double 'operation' }

  describe 'initialization' do
    it "accepts a type, parent, and hash of values" do
      expect{ described_class.new Riak::Crdt::Counter, parent, {} }.to_not raise_error
    end
  end

  describe 'containing' do
    describe 'registers' do
      let(:register_class){ Riak::Crdt::InnerRegister }
      subject do
        described_class.new register_class, parent, existing: 'existing'
      end

      it 'exposes them as frozen strings that are really Registers' do
        expect(subject[:existing]).to eq 'existing'
        expect(subject['existing']).to eq 'existing'
        expect(subject[:existing]).to be_an_instance_of register_class
        expect(subject['existing'].frozen?).to be
        expect{subject['existing'].gsub!('e', 'a')}.to raise_error(RuntimeError)
      end

      describe 'creating and updating' do

        let(:new_value){ 'the new value' }

        it 'asks the register class for an operation' do
          expect(register_class).to receive(:update).
            with(new_value).
            and_return(operation)

          expect(operation).
            to receive(:name=).
            with('existing')

          expect(parent).
            to receive(:operate).
            with(operation)

          subject['existing'] = new_value
        end
      end

      describe 'removing' do

        it 'asks the register class for a remove operation' do
          expect(register_class).
            to receive(:delete).
            and_return(operation)

          expect(operation).
            to receive(:name=).
            with('existing')

          expect(parent).
            to receive(:operate).
            with(operation)

          subject.delete 'existing'
        end
      end
    end
    describe 'flags' do
      let(:flag_class){ Riak::Crdt::InnerFlag }
      subject do
        described_class.new flag_class, parent, truthy: true, falsey: false
      end

      it 'exposes them as booleans' do
        expect(subject[:truthy]).to eq true
        expect(subject['falsey']).to eq false
      end

      it 'updates them' do
        expect(flag_class).
          to receive(:update).
          with(true).
          and_return(operation)

        expect(operation).
          to receive(:name=).
          with('become_truthy')

        expect(parent).
          to receive(:operate).
          with(operation)

        subject['become_truthy'] = true
      end

      it 'deletes them' do
        expect(flag_class).
          to receive(:delete).
          and_return(operation)

        expect(operation).
          to receive(:name=).
          with('become_deleted')

        expect(parent).
          to receive(:operate).
          with(operation)

        subject.delete 'become_deleted'
      end
    end
    describe 'counters' do
      let(:counter_class){ Riak::Crdt::InnerCounter }

      subject{ described_class.new counter_class, parent, zero: 0, one: 1 }

      it 'exposes existing ones as Counter instances' do
        expect(subject['zero']).to be_an_instance_of counter_class
        expect(subject['zero'].to_i).to eq 0

        expect(subject['one'].to_i).to eq 1
      end

      it 'exposes new ones as Counter instances' do
        expect(subject['new_zero']).to be_an_instance_of counter_class
        expect(subject['new_zero'].to_i).to eq 0
      end

      it 'allows incrementing and decrementing' do
        counter_name = 'counter'

        expect(parent).to receive(:operate) do |op|
          expect(op.name).to eq counter_name
          expect(op.type).to eq :counter
          expect(op.value).to eq 1
        end
        subject[counter_name].increment

        expect(parent).to receive(:operate) do |op|
          expect(op.name).to eq counter_name
          expect(op.type).to eq :counter
          expect(op.value).to eq -5
        end

        subject[counter_name].decrement 5
      end
    end
    describe 'sets' do
      let(:set_class){ Riak::Crdt::InnerSet }

      subject{ described_class.new set_class, parent, brewers: %w{aeropress clever v60}}

      it 'exposes existing ones as Set instances' do
        expect(subject['brewers']).to be_an_instance_of set_class
        expect(subject['brewers']).to include 'aeropress'
      end

      it 'exposes new ones as empty Set instances' do
        expect(subject['filters']).to be_an_instance_of set_class
        expect(subject['filters']).to be_empty
      end

      it 'allows adding and removing' do
        set_name = 'brewers'

        expect(parent).to receive(:operate) do |op|
          expect(op.name).to eq set_name
          expect(op.type).to eq :set
          expect(op.value).to eq add: 'frenchpress'
        end
        subject[set_name].add 'frenchpress'

        expect(parent).to receive(:operate) do |op|
          expect(op.name).to eq set_name
          expect(op.type).to eq :set
          expect(op.value).to eq remove: 'aeropress'
        end
        allow(parent).to receive(:context?).and_return(true)

        subject[set_name].remove 'aeropress'
      end
    end

    describe 'maps' do
      let(:map_class){ Riak::Crdt::InnerMap }

      let(:contents) do {a: {
            counters: {},
            flags: {},
            maps: {},
            registers: {'hello' => 'world'},
            sets: {}
          }}
        end

      let(:inner_map_name){ 'inner map' }

      subject do
        described_class.new map_class, parent, contents
      end

      it 'exposes existing ones as populated Map instances' do
        expect(subject['a']).to be_an_instance_of map_class
        expect(subject['a'].registers['hello']).to eq 'world'
      end

      it 'exposes new ones as empty Map instances' do
        expect(subject['b']).to be_an_instance_of map_class
        expect(subject['b'].registers['hello']).to be_nil
      end

      it 'cascades operations to a parent map' do
        expect(operation).
          to receive(:name=).
          with(inner_map_name)

        expect(parent).
          to receive(:operate).
          with(operation)

        subject.operate inner_map_name, operation
      end
    end
  end
end
