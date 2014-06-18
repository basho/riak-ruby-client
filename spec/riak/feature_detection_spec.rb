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
    it "should raise a NotImplementedError" do
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
