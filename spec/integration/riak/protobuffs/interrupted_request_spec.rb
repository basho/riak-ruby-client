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
require 'timeout'

describe 'Protocol Buffers', test_client: true do
  describe 'interrupted requests' do

    let(:bucket){ random_bucket 'interrupted_requests' }

    before do
      first = bucket.new 'first'
      first.data = 'first'
      first.content_type = 'text/plain'
      first.store

      second = bucket.new 'second'
      second.data = 'second'
      second.content_type = 'text/plain'
      second.store
    end

    it 'fails out when a request is interrupted, and never returns the wrong payload' do
      expect do
        Timeout.timeout 1 do
          loop do
            expect(bucket.get('first').data).to eq 'first'
          end
        end
      end.to raise_error Timeout::Error

      expect(bucket.get('second').data).to eq 'second'
    end
  end
end
