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

    # Determines the base_dir from control script or source dir
    def configure_base_dir
      # Read the 'riak' script.
      control_script_contents = (source + control_script_name).read
      # See if it uses nodetool by sourcing env.sh, if so, read the
      # env.sh instead, since it contains the setting of the base
      # directory.
      control_script_contents.match /\s*\.\s+"?(.*env\.sh)"?/ do |m|
        control_script_contents = Pathname.new(m[1]).read
      end
      # Find the RUNNER_BASE_DIR in the script. If it has shell
      # expansions in it, we're looking at a relative path and should
      # assume this is a source or devrel installation, and thus use
      # the parent directory as the base. Otherwise, if it's a regular
      # path, we can assume it's absolute and pointing to the lib dir.
      # This is where the 'releases' directory exists.
      control_script_contents.match /RUNNER_BASE_DIR=(.*)/ do |m|
        if m[1].include? "$"
          source.parent
        else
          Pathname.new(m[1].strip)
        end
      end
    end
  end
end
