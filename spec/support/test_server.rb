require 'riak/test_server'

RSpec.configure do |config|
  config.before(:each, :integration => true) do
    pending "Test server not working #{$test_server_fatal}" if $test_server_fatal
    begin
      unless $test_server
        config = YAML.load_file("spec/support/test_server.yml")
        $test_server = Riak::TestServer.create(:root => config['root'],
                                               :source => config['source'],
                                               :min_port => config['min_port'] || 15000)
        at_exit { $test_server.stop }
      end
      if example.metadata[:test_server] == false
        $test_server.stop
      else
        $test_server.create unless $test_server.exist?
        $test_server.start
      end
    rescue SocketError => e
      warn "Couldn't connect to Riak TestServer! #{$test_server.inspect}"
      warn "Skipping remaining integration tests."
      $test_server_fatal = e
    rescue => e
      warn "Can't run integration specs without the test server. Please create spec/support/test_server.yml."
      warn e.inspect
      $test_server_fatal = e
    end
  end

  config.after(:each, :integration => true) do
    if $test_server && !$test_server_fatal && example.metadata[:test_server] != false
      $test_server.drop
    end
  end
end
