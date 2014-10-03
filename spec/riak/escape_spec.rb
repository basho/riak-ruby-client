
require 'spec_helper'

describe Riak::Util::Escape do
  before :each do
    @object = Object.new
    @object.extend(Riak::Util::Escape)
  end

  it "uses URI by default for escaping" do
    Riak.escaper.should == CGI
  end

  context "when using CGI for escaping" do
    before { @oldesc, Riak.escaper = Riak.escaper, CGI }
    after { Riak.escaper = @oldesc }

    it "escapes standard non-safe characters" do
      @object.escape("some string").should == "some%20string"
      @object.escape("another^one").should == "another%5Eone"
      @object.escape("bracket[one").should == "bracket%5Bone"
    end

    it "escapes slashes" do
      @object.escape("some/inner/path").should == "some%2Finner%2Fpath"
    end

    it "converts the bucket or key to a string before escaping" do
      @object.escape(125).should == '125'
    end

    it "unescapes escaped strings" do
      @object.unescape("some%20string").should == "some string"
      @object.unescape("another%5Eone").should == "another^one"
      @object.unescape("bracket%5Bone").should == "bracket[one"
      @object.unescape("some%2Finner%2Fpath").should == "some/inner/path"
    end
  end

  context "when using URI for escaping" do
    before { @oldesc, Riak.escaper = Riak.escaper, URI }
    after { Riak.escaper = @oldesc }

    it "escapes standard non-safe characters" do
      @object.escape("some string").should == "some%20string"
      @object.escape("another^one").should == "another%5Eone"
      @object.escape("--one+two--").should == "--one%2Btwo--"
    end

    it "allows URI-safe characters" do
      @object.escape("sean@basho").should == "sean@basho"
    end

    it "escapes slashes" do
      @object.escape("some/inner/path").should == "some%2Finner%2Fpath"
    end

    it "escapes square brackets" do
      @object.escape("bracket[one").should == "bracket%5Bone"
      @object.escape("bracket]two").should == "bracket%5Dtwo"
    end

    it "converts the bucket or key to a string before escaping" do
      @object.escape(125).should == '125'
    end

    it "unescapes escaped strings" do
      @object.unescape("some%20string").should == "some string"
      @object.unescape("another%5Eone").should == "another^one"
      @object.unescape("bracket%5Bone").should == "bracket[one"
      @object.unescape("some%2Finner%2Fpath").should == "some/inner/path"
      @object.unescape("--one%2Btwo--").should == "--one+two--"
      @object.unescape("me%40basho.co").should == "me@basho.co"
    end
  end
end
