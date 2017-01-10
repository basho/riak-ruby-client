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
require 'riak'

describe 'Preflist', integration: true, test_client: true do
  let(:bucket){ random_bucket }
  let(:robject) do
    bucket.get_or_new(random_key).tap do |robj|
      robj.data = 'asdf'
      robj.store
    end
  end

  matcher :be_a_preflist do
    match do |actual|
      actual.is_a?(Array) &&
      actual.first.is_a?(Riak::PreflistItem)
    end
  end

  it 'is available from RObjects' do
    begin
      expect(robject.preflist).to be_a_preflist
    rescue Riak::ProtobuffsErrorResponse
      skip('preflists are not supported')
    end
  end

  it 'is available from Buckets' do
    begin
      expect(bucket.get_preflist robject.key).to be_a_preflist
    rescue Riak::ProtobuffsErrorResponse
      skip('preflists are not supported')
    end
  end

  it 'is available from the Client' do
    begin
      expect(test_client.get_preflist bucket.name, robject.key).to be_a_preflist
    rescue Riak::ProtobuffsErrorResponse
      skip('preflists are not supported')
    end
  end
end
