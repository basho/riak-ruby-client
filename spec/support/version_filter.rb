require 'rubygems'

RSpec.configure do |config|
  config.before(:each, :version => lambda {|v| !!v }) do
    required = Gem::Requirement.create(example.metadata[:version])
    actual = Gem::Version.new(test_server.version)
    pending("SKIP: Tests feature for Riak #{required.to_s}, but testing against #{actual.to_s}",
            :unless => required.satisfied_by?(actual))
  end
end
