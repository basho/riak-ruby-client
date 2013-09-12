require 'riak/test_server'

module TestServerSupport
  def test_server
    unless $test_server
      begin
        require 'yaml'
        config = YAML.load_file(File.expand_path("../test_server.yml", __FILE__))
        $test_server = Riak::TestServer.create(:root => config['root'],
                                         :source => config['source'],
                                         :min_port => config['min_port'] || 15000)
      rescue SocketError => e
        warn "Couldn't connect to Riak TestServer! #{$test_server.inspect}"
        warn "Skipping remaining integration tests."
        warn_crash_log
        $test_server_fatal = e
      rescue => e
        warn "Can't run integration specs without the test server. Please create/verify spec/support/test_server.yml."
        warn "Skipping remaining integration tests."
        warn e.inspect
        warn_crash_log
        $test_server_fatal = e
      end
    end
    $test_server
  end

  def test_server_fatal
    $test_server_fatal
  end

  def warn_crash_log
    if $test_server && crash_log = $test_server.log + 'crash.log'
      warn crash_log.read if crash_log.exist?
    end
  end
end

RSpec.configure do |config|
  config.include TestServerSupport, :test_server => true

  config.before(:each, :test_server => true) do
    fail "Test server not working: #{test_server_fatal}" if test_server_fatal
    if example.metadata[:test_server] == false
      test_server.stop
    else
      test_server.create unless test_server.exist?
      test_server.start
    end
  end

  config.after(:each, :test_server => true) do
    if test_server && !test_server_fatal && test_server.started? && example.metadata[:test_server] != false
      test_server.drop
    end
  end

  config.after(:suite) do
    $test_server.stop if $test_server
  end
end
