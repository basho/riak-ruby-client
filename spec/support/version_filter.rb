RSpec.configure do |config|
  config.before(:each) do
    if respond_to?(:test_server) && example.metadata[:test_server] != false && example.metadata[:version]
      required = example.metadata[:version]
      actual = test_server.version
      pending("SKIP: Tests feature for Riak #{required}, but testing against #{actual}") if actual < required
    end
  end
end
