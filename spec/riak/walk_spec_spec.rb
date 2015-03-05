require 'spec_helper'

describe Riak::WalkSpec do
  describe "initializing" do
    describe "with a hash" do
      it "is empty by default" do
        spec = Riak::WalkSpec.new({})
        expect(spec.bucket).to eq("_")
        expect(spec.tag).to eq("_")
        expect(spec.keep).to be_falsey
      end

      it "extracts the bucket" do
        spec = Riak::WalkSpec.new({:bucket => "foo"})
        expect(spec.bucket).to eq("foo")
        expect(spec.tag).to eq("_")
        expect(spec.keep).to be_falsey
      end

      it "extracts the tag" do
        spec = Riak::WalkSpec.new({:tag => "foo"})
        expect(spec.bucket).to eq("_")
        expect(spec.tag).to eq("foo")
        expect(spec.keep).to be_falsey
      end

      it "extracts the keep" do
        spec = Riak::WalkSpec.new({:keep => true})
        expect(spec.bucket).to eq("_")
        expect(spec.tag).to eq("_")
        expect(spec.keep).to be_truthy
      end
    end

    describe "with three arguments for bucket, tag, and keep" do
      it "assigns the bucket, tag, and keep" do
        spec = Riak::WalkSpec.new("foo", "next", false)
        expect(spec.bucket).to eq("foo")
        expect(spec.tag).to eq("next")
        expect(spec.keep).to be_falsey
      end

      it "specifies the '_' bucket when false or nil" do
        spec = Riak::WalkSpec.new(nil, "next", false)
        expect(spec.bucket).to eq("_")
        spec = Riak::WalkSpec.new(false, "next", false)
        expect(spec.bucket).to eq("_")
      end

      it "specifies the '_' tag when false or nil" do
        spec = Riak::WalkSpec.new("foo", nil, false)
        expect(spec.tag).to eq("_")
        spec = Riak::WalkSpec.new("foo", false, false)
        expect(spec.tag).to eq("_")
      end

      it "make the keep falsey when false or nil" do
        spec = Riak::WalkSpec.new(nil, nil, nil)
        expect(spec.keep).to be_falsey
        spec = Riak::WalkSpec.new(nil, nil, false)
        expect(spec.keep).to be_falsey
      end
    end

    it "raises an ArgumentError for invalid arguments" do
      expect { Riak::WalkSpec.new }.to raise_error(ArgumentError)
      expect { Riak::WalkSpec.new("foo") }.to raise_error(ArgumentError)
      expect { Riak::WalkSpec.new("foo", "bar") }.to raise_error(ArgumentError)
    end
  end

  describe "converting to a string" do
    before :each do
      @spec = Riak::WalkSpec.new({})
    end

    it "converts to the empty spec by default" do
      expect(@spec.to_s).to eq("_,_,_")
    end

    it "includes the bucket when set" do
      @spec.bucket = "foo"
      expect(@spec.to_s).to eq("foo,_,_")
    end

    it "includes the tag when set" do
      @spec.tag = "next"
      expect(@spec.to_s).to eq("_,next,_")
    end

    it "includes the keep when true" do
      @spec.keep = true
      expect(@spec.to_s).to eq("_,_,1")
    end
  end

  describe "creating from a list of parameters" do
    it "detects hashes and WalkSpecs interleaved with other parameters" do
      specs = Riak::WalkSpec.normalize(nil, "next", nil, {:bucket => "foo"}, Riak::WalkSpec.new({:tag => "child", :keep => true}))
      expect(specs.size).to eq(3)
      expect(specs).to be_all {|s| s.kind_of?(Riak::WalkSpec) }
      expect(specs.join("/")).to eq("_,next,_/foo,_,_/_,child,1")
    end

    it "raises an error when given invalid number of parameters" do
      expect { Riak::WalkSpec.normalize("foo") }.to raise_error(ArgumentError)
    end
  end

  describe "matching other objects with ===" do
    before :each do
      @spec = Riak::WalkSpec.new({})
    end

    it "doesn't match objects that aren't links or walk specs" do
      expect(@spec).not_to be === "foo"
    end

    describe "matching links" do
      before :each do
        @link = Riak::Link.new("/riak/foo/bar", "next")
      end

      it "matches a link when the bucket and tag are not specified" do
        expect(@spec).to be === @link
      end

      it "matches a link when the bucket is the same" do
        @spec.bucket = "foo"
        expect(@spec).to be === @link
      end

      it "doesn't match a link when the bucket is different" do
        @spec.bucket = "bar"
        expect(@spec).not_to be === @link
      end

      it "matches a link when the tag is the same" do
        @spec.tag = "next"
        expect(@spec).to be === @link
      end

      it "doesn't match a link when the tag is different" do
        @spec.tag = "previous"
        expect(@spec).not_to be === @link
      end

      it "matches a link when the bucket and tag are the same" do
        @spec.bucket = "foo"
        expect(@spec).to be === @link
      end
    end

    describe "matching walk specs" do
      before :each do
        @other = Riak::WalkSpec.new({})
      end

      it "matches a walk spec that is equivalent" do
        expect(@spec).to be === @other
      end

      it "matches a walk spec that has a different keep value" do
        @other.keep = true
        expect(@spec).not_to be === @other
      end

      it "matches a walk spec with a more specific bucket" do
        @other.bucket = "foo"
        expect(@spec).to be === @other
      end

      it "matches a walk spec with the same bucket" do
        @other.bucket = "foo"
        @spec.bucket = "foo"
        expect(@spec).to be === @other
      end

      it "doesn't match a walk spec with a different bucket" do
        @other.bucket = "foo"
        @spec.bucket = "bar"
        expect(@spec).not_to be === @other
      end

      it "doesn't match a walk spec with a more specific tag" do
        @other.tag = "next"
        expect(@spec).to be === @other
      end

      it "matches a walk spec with the same tag" do
        @other.tag = "next"
        @spec.tag = "next"
        expect(@spec).to be === @other
      end

      it "doesn't match a walk spec with a different tag" do
        @other.tag = "next"
        @spec.tag = "previous"
        expect(@spec).not_to be === @other
      end
    end
  end
end
