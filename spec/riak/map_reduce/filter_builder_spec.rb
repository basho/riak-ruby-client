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

describe Riak::MapReduce::FilterBuilder do
  subject { Riak::MapReduce::FilterBuilder.new }
  it "evaluates the passed block on initialization" do
    expect(subject.class.new do
      matches "foo"
    end.to_a).to eq([[:matches, "foo"]])
  end

  it "adds filters to the list" do
    subject.to_lower
    subject.similar_to("ripple", 3)
    expect(subject.to_a).to eq([[:to_lower], [:similar_to, "ripple", 3]])
  end

  it "adds a logical operation with a block" do
    subject.OR do
      starts_with "foo"
      ends_with "bar"
    end
    expect(subject.to_a).to eq([[:or, [[:starts_with, "foo"], [:ends_with, "bar"]]]])
  end

  it "raises an error on a filter arity mismatch" do
    expect { subject.less_than }.to raise_error(ArgumentError)
  end

  it "raises an error when a block is not given to a logical operation" do
    expect { subject._or }.to raise_error(ArgumentError)
  end
end
