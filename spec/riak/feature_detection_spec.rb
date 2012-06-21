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
    before { subject.stub!(:get_server_version).and_return("0.14.2") }
    it { should_not be_mapred_phaseless }
    it { should_not be_pb_indexes }
    it { should_not be_pb_search }
  end

  context "when the Riak version is 1.0.x" do
    before { subject.stub!(:get_server_version).and_return("1.0.3") }
    it { should_not be_mapred_phaseless }
    it { should_not be_pb_indexes }
    it { should_not be_pb_search }
  end

  context "when the Riak version is 1.1.x" do
    before { subject.stub!(:get_server_version).and_return("1.1.4") }
    it { should be_mapred_phaseless }
    it { should_not be_pb_indexes }
    it { should_not be_pb_search }
  end

  context "when the Riak version is 1.2.x" do
    before { subject.stub!(:get_server_version).and_return("1.2.0") }
    it { should be_mapred_phaseless }
    it { should be_pb_indexes }
    it { should be_pb_search }
  end
end
