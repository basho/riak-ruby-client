require 'pathname'

module Riak
  class Node
    # @return [String] the version of the Riak node
    def version
      @version ||= configure_version
    end

    # @return [Pathname] the location of Riak installation, aka RUNNER_BASE_DIR
    def base_dir
      @base_dir ||= configure_base_dir
    end

    protected
    # Detects the Riak version from the generated release
    def configure_version
      if base_dir
        versions = (base_dir + 'releases' + 'start_erl.data').read
        versions.split(" ")[1]
      end
    end

    # Determines the base_dir from source parent
    def configure_base_dir
      source.parent
    end
  end
end
