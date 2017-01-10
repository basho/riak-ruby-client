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

describe Riak do
  require 'riak/core_ext/to_param'

  it "converts params correctly" do
    expect({ :name => 'David', :nationality => 'Danish' }.to_param).to eq("name=David&nationality=Danish")
  end

  # Based on the activesupport implementation.
  # https://github.com/rails/rails/blob/master/activesupport/lib/active_support/core_ext/object/to_param.rb
  it "converts namespaced params correctly" do
    expect({ :name => 'David', :nationality => 'Danish' }.to_param('user')).to eq("user%5Bname%5D=David&user%5Bnationality%5D=Danish")
  end

end
