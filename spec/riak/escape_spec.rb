
require 'spec_helper'

describe Riak::Util::Escape do
  before :each do
    @object = Object.new
    @object.extend(Riak::Util::Escape)
  end

  it "uses URI by default for escaping" do
    expect(Riak.escaper).to eq(URI)
  end

  context "when using CGI for escaping" do
    before { @oldesc, Riak.escaper = Riak.escaper, CGI }
    after { Riak.escaper = @oldesc }

    it "escapes standard non-safe characters" do
      expect(@object.escape("some string")).to eq("some%20string")
      expect(@object.escape("another^one")).to eq("another%5Eone")
      expect(@object.escape("bracket[one")).to eq("bracket%5Bone")
    end

    it "escapes slashes" do
      expect(@object.escape("some/inner/path")).to eq("some%2Finner%2Fpath")
    end

    it "converts the bucket or key to a string before escaping" do
      expect(@object.escape(125)).to eq('125')
    end

    it "unescapes escaped strings" do
      expect(@object.unescape("some%20string")).to eq("some string")
      expect(@object.unescape("another%5Eone")).to eq("another^one")
      expect(@object.unescape("bracket%5Bone")).to eq("bracket[one")
      expect(@object.unescape("some%2Finner%2Fpath")).to eq("some/inner/path")
    end
  end

  context "when using URI for escaping" do
    before { @oldesc, Riak.escaper = Riak.escaper, URI }
    after { Riak.escaper = @oldesc }

    it "escapes standard non-safe characters" do
      expect(@object.escape("some string")).to eq("some%20string")
      expect(@object.escape("another^one")).to eq("another%5Eone")
      expect(@object.escape("--one+two--")).to eq("--one%2Btwo--")
    end

    it "allows URI-safe characters" do
      expect(@object.escape("bracket[one")).to eq("bracket[one")
      expect(@object.escape("sean@basho")).to eq("sean@basho")
    end

    it "escapes slashes" do
      expect(@object.escape("some/inner/path")).to eq("some%2Finner%2Fpath")
    end

    it "converts the bucket or key to a string before escaping" do
      expect(@object.escape(125)).to eq('125')
    end

    it "unescapes escaped strings" do
      expect(@object.unescape("some%20string")).to eq("some string")
      expect(@object.unescape("another%5Eone")).to eq("another^one")
      expect(@object.unescape("bracket%5Bone")).to eq("bracket[one")
      expect(@object.unescape("some%2Finner%2Fpath")).to eq("some/inner/path")
      expect(@object.unescape("--one%2Btwo--")).to eq("--one+two--")
      expect(@object.unescape("me%40basho.co")).to eq("me@basho.co")
    end
  end
end
