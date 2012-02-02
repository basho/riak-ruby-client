RSpec.configure do |config|
  config.before(:each, :integration => true,
                :version => lambda {|v| !!v },
                :test_server => lambda {|ts| ts != false }) do
    required = example.metadata[:version]
    actual = test_server.version
    case required
    when String
      pending("SKIP: Tests feature for Riak #{required}, but testing against #{actual}") if actual < required
    when Range
      pending("SKIP: Tests feature for Riak versions #{required.begin} through #{required.end}, but testing against #{actual}") unless required.include?(actual)
    end
  end
end
