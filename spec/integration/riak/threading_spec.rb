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

describe "Multithreaded client", :test_client => true do
  if ENV['TRAVIS'] == 'true' && RUBY_PLATFORM == 'java'
    skip 'multithreaded client tests time out on Travis CI'
    break
  end
  class Synchronizer
    def initialize(n)
      @mutex = Mutex.new
      @n = n
      @waiting = Set.new
    end

    def sync
      stop = false
      @mutex.synchronize do
        @waiting << Thread.current

        if @waiting.size >= @n
          # All threads are waiting.
          @waiting.each do |t|
            t.run
          end
        else
          stop = true
        end
      end

      if stop
        Thread.stop
      end
    end
  end

  def threads(n, opts = {})
    if opts[:synchronize]
      s1 = Synchronizer.new n
      s2 = Synchronizer.new n
    end

    threads = (0...n).map do |i|
      Thread.new do
        if opts[:synchronize]
          s1.sync
        end

        yield i

        if opts[:synchronize]
          s2.sync
        end
      end
    end

    threads.each do |t|
      t.join
    end
  end

  [
   {:protobuffs_backend => :Beefcake}
  ].each do |opts|
    describe opts.inspect do
      before do
        @bucket = random_bucket 'threading'
      end

      it 'gets in parallel' do
        data = "the gun is good"
        ro = @bucket.new('test')
        ro.content_type = "application/json"
        ro.data = [data]
        ro.store

        threads 10, :synchronize => true do
          x = @bucket['test']
          expect(x.content_type).to eq("application/json")
          expect(x.data).to eq([data])
        end
      end

      it 'puts in parallel' do
        data = "the tabernacle is indestructible and everlasting"

        n = 10
        threads n, :synchronize => true do |i|
          x = @bucket.new("test-#{i}")
          x.content_type = "application/json"
          x.data = ["#{data}-#{i}"]
          x.store
        end

        (0...n).each do |i|
          read = @bucket["test-#{i}"]
          expect(read.content_type).to eq("application/json")
          expect(read.data).to eq(["#{data}-#{i}"])
        end
      end

      # This is a 1.0+ spec because putting with the same client ID
      # will not create siblings on 0.14 in the same way. This will
      # also likely fail for nodes with vnode_vclocks = false.
      it 'puts conflicts in parallel' do
        @bucket.allow_mult = true
        expect(@bucket.allow_mult).to eq(true)

        init = @bucket.new('test')
        init.content_type = "application/json"
        init.data = ''
        init.store

        # Create conflicting writes
        n = 10
        s = Synchronizer.new n
        threads n, :synchronize => true do |i|
          x = @bucket["test"]
          s.sync
          x.data = [i]
          x.store
        end

        read = @bucket["test"]
        expect(read.conflict?).to eq(true)
        expect(read.siblings.map do |sibling|
          sibling.data.first
        end.to_set).to eq((0...n).to_set)
      end

      it 'lists-keys and gets in parallel', :slow => true do
        count = 100
        threads = 2

        # Create items
        count.times do |i|
          o = @bucket.new("#{i}")
          o.content_type = 'application/json'
          o.data = [i]
          o.store
        end

        threads(threads) do
          set = Set.new
          @bucket.keys do |stream|
            stream.each do |key|
              set.merge @bucket[key].data
            end
          end
          expect(set).to eq((0...count).to_set)
        end
      end
    end
  end
end
