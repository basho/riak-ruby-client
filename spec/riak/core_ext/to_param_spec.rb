
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
