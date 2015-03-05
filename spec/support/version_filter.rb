require 'rubygems'

RSpec.configure do |config|
  config.before(:each, version: ->(v) { v }) do |example|
    required = Gem::Requirement.create(example.metadata[:version])
    actual = Gem::Version.new(test_server.version)
    skip(
      "SKIP: Tests feature for Riak #{required}, but testing against #{actual}",
      unless: required.satisfied_by?(actual)
    )
  end
end
