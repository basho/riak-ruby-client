require 'riak/test_server'

# This class is used for running the integration suite against
# existing Riak nodes that have been preconfigured for test mode, e.g.
# as part of the riak_test integration suite. This is only supported
# on Riak versions > 1.2, with the KV backend set to memory with the
# 'test' flag, and the Search backend set to the backend bundled with
# the client (called riak_search_test_backend).
class PrebuiltTestServer
  def self.valid?
    %W{RIAK_ROOT_DIR RIAK_NODE_NAME HTTP_PORT PB_PORT RIAK_VERSION}.all? {|e| ENV[e] }
  end

  attr_reader :http_port, :pb_port, :version, :root, :name

  def initialize
    @root = Pathname(ENV['RIAK_ROOT_DIR'])
    @name = ENV['RIAK_NODE_NAME'].dup
    @version = ENV['RIAK_VERSION'].dup[/\d+\.\d+\.\d+/, 0]
    @http_port = ENV['HTTP_PORT'].to_i
    @pb_port = ENV['PB_PORT'].to_i
  end

  def pipe
    # Have to remove leading slash on root
    @pipe ||= Pathname("/tmp") + @root.to_s[1..-1]
  end

  def exist?; true; end
  def stop; end
  def start; end
  def started?; true; end

  def drop
    begin
      maybe_attach
      @console.command "riak_kv_memory_backend:reset()."
      @console.command "riak_search_test_backend:reset()."
    rescue IOError
      retry
    end
  end

  def attach
    Riak::Node::Console.open self
  end

  protected
  # Tries to reattach the console if it's closed
  def maybe_attach
    unless open?
      @console.close if @console && !@console.frozen?
      @console = attach
    end
  end

  def open?
    @console && @console.open?
  end
end

module PrebuiltTestServerSupport
  def test_server
    unless $test_server
      if PrebuiltTestServer.valid?
        $test_server = PrebuiltTestServer.new
      else
        super
      end
    end
    $test_server
  end
end

RSpec.configure do |config|
  config.include PrebuiltTestServerSupport, :integration => true
end
