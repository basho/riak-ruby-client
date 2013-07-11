require 'spec_helper'

describe Riak::Counter do
  describe "initialization" do
    it "should set the bucket"
    it "should set the key"
    it "should require allow_mult"
    it "should require http"
  end
  
  describe "incrementing and decrementing" do
    it "should increment by 1 by default"
    it "should support incrementing by positive numbers"
    it "should support incrementing by negative numbers"

    it "should decrement by 1 by default"
    it "should support decrementing by positive numbers"
    it "should support decrementing by negative numbers"
  end
end
