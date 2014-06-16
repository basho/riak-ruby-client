$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start
end

require 'rubygems' # Use the gems path only for the spec suite
require 'riak'
require 'rspec'
require 'stringio'

# Only the tests should really get away with this.
Riak.disable_list_keys_warnings = true

%w[integration_setup
   version_filter
   sometimes
   wait_until
   search_corpus_setup
   unified_backend_examples
   test_client].each do |file|
  require File.join("support", file)
end

RSpec.configure do |config|
  #config.debug = true
  config.mock_with :rspec

  config.before(:each) do
    Riak::RObject.on_conflict_hooks.clear
  end

  if TestClient.test_client_configuration[:authentication]
    config.filter_run_excluding no_security: true
  else
    config.filter_run_excluding yes_security: true
  end

  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  if defined?(::Java)
    config.seed = Time.now.utc
  else
    config.order = :random
  end
end
