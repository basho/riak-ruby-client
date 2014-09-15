require 'spec_helper'

describe Riak::MapReduce::Phase do
  before :each do
    @js_fun = "function(v,_,_){ return v['values'][0]['data']; }"
    @erl_fun = "fun(Obj, _KeyData, _Arg) -> [{riak_object:key(Obj), riak_object:get_value(Obj)}] end."
  end

  it "initializes with a type and a function" do
    phase = Riak::MapReduce::Phase.new(:type => :map, :function => @js_fun, :language => "javascript")
    expect(phase.type).to eq(:map)
    expect(phase.function).to eq(@js_fun)
    expect(phase.language).to eq("javascript")
  end

  it "initializes with a type and an MF" do
    phase = Riak::MapReduce::Phase.new(:type => :map, :function => ["module", "function"], :language => "erlang")
    expect(phase.type).to eq(:map)
    expect(phase.function).to eq(["module", "function"])
    expect(phase.language).to eq("erlang")
  end

  it "initializes with a type and a bucket/key" do
    phase = Riak::MapReduce::Phase.new(:type => :map, :function => {:bucket => "funs", :key => "awesome_map"}, :language => "javascript")
    expect(phase.type).to eq(:map)
    expect(phase.function).to eq({:bucket => "funs", :key => "awesome_map"})
    expect(phase.language).to eq("javascript")
  end

  it "assumes the language is erlang when the function is an array" do
    phase = Riak::MapReduce::Phase.new(:type => :map, :function => ["module", "function"])
    expect(phase.language).to eq("erlang")
  end

  it "assumes the language is javascript when the function is a string and starts with function" do
    phase = Riak::MapReduce::Phase.new(:type => :map, :function => @js_fun)
    expect(phase.language).to eq("javascript")
  end

  it "assumes the language is erlang when the function is a string and starts with anon fun" do
    phase = Riak::MapReduce::Phase.new(:type => :map, :function => @erl_fun)
    expect(phase.language).to eq("erlang")
  end

  it "assumes the language is javascript when the function is a hash" do
    phase = Riak::MapReduce::Phase.new(:type => :map, :function => {:bucket => "jobs", :key => "awesome_map"})
    expect(phase.language).to eq("javascript")
  end

  it "accepts a WalkSpec for the function when a link phase" do
    phase = Riak::MapReduce::Phase.new(:type => :link, :function => Riak::WalkSpec.new({}))
    expect(phase.function).to be_kind_of(Riak::WalkSpec)
  end

  it "raises an error if a WalkSpec is given for a phase type other than :link" do
    expect { Riak::MapReduce::Phase.new(:type => :map, :function => Riak::WalkSpec.new({})) }.to raise_error(ArgumentError)
  end

  describe "converting to JSON for the job" do
    before :each do
      @phase = Riak::MapReduce::Phase.new(:type => :map, :function => "")
    end

    [:map, :reduce].each do |type|
      describe "when a #{type} phase" do
        before :each do
          @phase.type = type
        end

        it "is an object with a single key of '#{type}'" do
          expect(@phase.to_json).to match(/^\{"#{type}":/)
        end

        it "includes the language" do
          expect(@phase.to_json).to match(/"language":/)
        end

        it "includes the keep value" do
          expect(@phase.to_json).to match(/"keep":false/)
          @phase.keep = true
          expect(@phase.to_json).to match(/"keep":true/)
        end

        it "includes the function source when the function is a source string" do
          @phase.function = "function(v,_,_){ return v; }"
          expect(@phase.to_json).to include(@phase.function)
          expect(@phase.to_json).to match(/"source":/)
        end

        it "includes the function name when the function is not a lambda" do
          @phase.function = "Riak.mapValues"
          expect(@phase.to_json).to include('"name":"Riak.mapValues"')
          expect(@phase.to_json).not_to include('"source"')
        end

        it "includes the bucket and key when referring to a stored function" do
          @phase.function = {:bucket => "design", :key => "wordcount_map"}
          expect(@phase.to_json).to include('"bucket":"design"')
          expect(@phase.to_json).to include('"key":"wordcount_map"')
        end

        it "includes the module and function when invoking an Erlang function" do
          @phase.function = ["riak_mapreduce", "mapreduce_fun"]
          expect(@phase.to_json).to include('"module":"riak_mapreduce"')
          expect(@phase.to_json).to include('"function":"mapreduce_fun"')
        end
      end
    end

    describe "when a link phase" do
      before :each do
        @phase.type = :link
        @phase.function = {}
      end

      it "is an object of a single key 'link'" do
        expect(@phase.to_json).to match(/^\{"link":/)
      end

      it "includes the bucket" do
        expect(@phase.to_json).to match(/"bucket":"_"/)
        @phase.function[:bucket] = "foo"
        expect(@phase.to_json).to match(/"bucket":"foo"/)
      end

      it "includes the tag" do
        expect(@phase.to_json).to match(/"tag":"_"/)
        @phase.function[:tag] = "parent"
        expect(@phase.to_json).to match(/"tag":"parent"/)
      end

      it "includes the keep value" do
        expect(@phase.to_json).to match(/"keep":false/)
        @phase.keep = true
        expect(@phase.to_json).to match(/"keep":true/)
        @phase.keep = false
        @phase.function[:keep] = true
        expect(@phase.to_json).to match(/"keep":true/)
      end
    end
  end
end
