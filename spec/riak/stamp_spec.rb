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
require 'riak/stamp'

describe Riak::Stamp, test_client: true, integration: true do
  subject { described_class.new test_client }
  it "generates always increasing integer identifiers" do
    1000.times do
      one = subject.next
      two = subject.next
      expect([one, two]).to be_all {|i| Integer === i }
      expect(two).to be > one
    end
  end

  it "delays until the next millisecond when the sequence overflows" do
    old = subject.instance_variable_get(:@timestamp) + 0
    subject.instance_variable_set(:@sequence, described_class::SEQUENCE_MASK)
    count = 0
    # Simulate the time_gen method returning the same thing multiple times
    allow(subject).to receive(:time_gen) do
      count += 1
      if count < 10
        old
      else
        old + 1
      end
    end
    expect((subject.next >> described_class::TIMESTAMP_SHIFT) & described_class::TIMESTAMP_MASK).to eq(old + 1)
  end

  it "raises an exception when the system clock moves backwards" do
    old = subject.instance_variable_get(:@timestamp)
    expect(subject).to receive(:time_gen).and_return(old - 10)
    expect {
      subject.next
    }.to raise_error(Riak::BackwardsClockError)
  end

  # The client/worker ID should be used for disambiguation, not for
  # primary ordering.  This breaks from the Snowflake model where the
  # worker ID is in more significant bits.
  it "uses the client ID as the bottom component of the identifier" do
    expect(subject.next & described_class::CLIENT_ID_MASK).to eq(subject.client.client_id.hash & described_class::CLIENT_ID_MASK)
  end

  context "using a non-integer client ID" do
    subject { described_class.new(Riak::Client.new(:client_id => "ripple")) }
    let(:hash) { "ripple".hash }

    it "uses the hash of the client ID as the bottom component of the identifier" do
      expect(subject.next & described_class::CLIENT_ID_MASK).to eq(subject.client.client_id.hash & described_class::CLIENT_ID_MASK)
    end
  end
end
