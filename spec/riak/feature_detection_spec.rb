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
require 'riak/client/feature_detection'

describe Riak::Client::FeatureDetection do
  let(:klass) {
    Class.new do
      include Riak::Client::FeatureDetection
    end
  }
  subject { klass.new }

  context "when the get_server_version is unimplemented" do
    it "raises a NotImplementedError" do
      expect { subject.server_version }.to raise_error(NotImplementedError)
    end
  end

  context "when the Riak version is 0.14.x" do
    before { allow(subject).to receive(:get_server_version).and_return("0.14.2") }
    it { is_expected.not_to be_mapred_phaseless }
    it { is_expected.not_to be_pb_indexes }
    it { is_expected.not_to be_pb_search }
    it { is_expected.not_to be_pb_conditionals }
    it { is_expected.not_to be_quorum_controls }
    it { is_expected.not_to be_tombstone_vclocks }
    it { is_expected.not_to be_pb_head }
    it { is_expected.not_to be_http_props_clearable }
  end

  context "when the Riak version is 1.0.x" do
    before { allow(subject).to receive(:get_server_version).and_return("1.0.3") }
    it { is_expected.not_to be_mapred_phaseless }
    it { is_expected.not_to be_pb_indexes }
    it { is_expected.not_to be_pb_search }
    it { is_expected.to be_pb_conditionals }
    it { is_expected.to be_quorum_controls }
    it { is_expected.to be_tombstone_vclocks }
    it { is_expected.to be_pb_head }
    it { is_expected.not_to be_http_props_clearable }
  end

  context "when the Riak version is 1.1.x" do
    before { allow(subject).to receive(:get_server_version).and_return("1.1.4") }
    it { is_expected.to be_mapred_phaseless }
    it { is_expected.not_to be_pb_indexes }
    it { is_expected.not_to be_pb_search }
    it { is_expected.to be_pb_conditionals }
    it { is_expected.to be_quorum_controls }
    it { is_expected.to be_tombstone_vclocks }
    it { is_expected.to be_pb_head }
    it { is_expected.not_to be_http_props_clearable }
  end

  context "when the Riak version is 1.2.x" do
    before { allow(subject).to receive(:get_server_version).and_return("1.2.1") }
    it { is_expected.to be_mapred_phaseless }
    it { is_expected.to be_pb_indexes }
    it { is_expected.to be_pb_search }
    it { is_expected.to be_pb_conditionals }
    it { is_expected.to be_quorum_controls }
    it { is_expected.to be_tombstone_vclocks }
    it { is_expected.to be_pb_head }
    it { is_expected.not_to be_http_props_clearable }
  end

  context "when the Riak version is 1.3.x" do
    before { allow(subject).to receive(:get_server_version).and_return("1.3.0") }
    it { is_expected.to be_mapred_phaseless }
    it { is_expected.to be_pb_indexes }
    it { is_expected.to be_pb_search }
    it { is_expected.to be_pb_conditionals }
    it { is_expected.to be_quorum_controls }
    it { is_expected.to be_tombstone_vclocks }
    it { is_expected.to be_pb_head }
    it { is_expected.to be_http_props_clearable }
  end
end
