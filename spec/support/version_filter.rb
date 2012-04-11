require 'rubygems'

RSpec.configure do |config|
  config.before(:each, :integration => true,
                :version => lambda {|v| !!v },
                :test_server => lambda {|ts| ts != false }) do
    required = example.metadata[:version]
    actual = Gem::Version.new(test_server.version)
    case required
    when String
      required = Gem::Requirement.create(">= #{required}")
    when Range
      required = Gem::Requirement.create([">= #{required.begin}", "<= #{required.end}"])
    end
    pending("SKIP: Tests feature for Riak #{required.to_s}, but testing against #{actual.to_s}") unless required.satisfied_by?(actual)
  end
end
