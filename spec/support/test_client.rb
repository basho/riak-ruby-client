module TestClient
  def test_client
    if defined? $test_client and $test_client.ping
      return $test_client
    end

    candidate_client = Riak::Client.new test_client_configuration

    live = candidate_client.ping

    return $test_client = candidate_client if live
  end

  def test_client_configuration
    TestClient.test_client_configuration
  end

  def self.test_client_configuration
    if defined? $test_client_configuration
      return $test_client_configuration
    end

    config_path = File.expand_path '../test_client.yml', __FILE__
    config = YAML.load_file(config_path).symbolize_keys

    if config[:nodes]
      new_nodes = config[:nodes].map(&:symbolize_keys)
      config[:nodes] = new_nodes
    end

    $test_client_configuration = config
  end

  def random_bucket(name = 'test_client')
    bucket_name = [name, Time.now.to_i, random_key].join('-')
    test_client.bucket bucket_name
  end

  def random_key
    rand(36**10).to_s(36)
  end
end

RSpec.configure do |config|
  config.include TestClient, test_client: true
end
