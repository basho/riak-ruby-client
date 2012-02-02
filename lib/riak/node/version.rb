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

    # Determines the base_dir from source control script
    def configure_base_dir
      # Use the script from the source directory so we don't require
      # it to be generated first.
      (source + control_script_name).each_line.find {|l| l =~ /^RUNNER_BASE_DIR=(.*)/ }

      # There should only be one matching line, so the contents of $1
      # will be the matched path. If there's nothing matched, we
      # return nil.
      case $1
      when '${RUNNER_SCRIPT_DIR%/*}'
        source.parent
      when String
        Pathname.new($1).expand_path
      else
        nil
      end
    end
  end
end
