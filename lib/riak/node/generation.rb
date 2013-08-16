require 'yaml'

module Riak
  class Node
    # Does the node exist on disk?
    def exist?
      manifest.exist?
    end

    # Deletes the node and regenerates it.
    def recreate
      delete
      create
    end

    # Generates the node.
    def create
      unless exist?
        touch_ssl_distribution_args
        copy_directories
        write_scripts
        write_vm_args
        write_app_config
        write_manifest
      end
    end

    # Clears data from known data directories. Stops the node if it is
    # running.
    def drop
      was_started = started?
      stop if was_started
      data.children.each do |item|
        if item.directory?
          item.children.each {|c| c.rmtree }
        else
          item.delete
        end
      end
      start if was_started
    end

    # Removes the node from disk and freezes the object.
    def destroy
      delete
      freeze
    end

    protected
    def delete
      stop unless stopped?
      root.rmtree if root.exist?
    end

    def copy_directories
      root.mkpath
      raise 'Source is not a directory!' unless base_dir.directory?

      base_dir.each_child do |dir|
        basename = dir.basename.to_s
        next if NODE_DIR_SKIP_LIST.include? basename.to_sym
        target = Pathname.new("#{root.to_s}")
        target.mkpath
        FileUtils.cp_r(dir.to_s,target)
      end
    end

    def write_vm_args
      (etc + 'vm.args').open('w') do |f|
        vm.each do |k,v|
          f.puts "#{k} #{v}"
        end
      end
    end

    def write_app_config
      (etc + 'app.config').open('w') do |f|
        f.write to_erlang_config(env) + '.'
      end
    end

    def write_scripts
      if version >= '1.4.0'
        [env_script].each {|s| write_script(s) }
      else
        [control_script, admin_script].each {|s| write_script(s) }
      end
    end

    def write_script(target)
      source_script = source.parent + target.relative_path_from(target.parent.parent)
      target.open('wb') do |f|
        source_script.readlines.each do |line|
          line.sub!(/(RUNNER_SCRIPT_DIR=)(.*)/, '\1' + bin.to_s)
          line.sub!(/(RUNNER_ETC_DIR=)(.*)/, '\1' + etc.to_s)
          line.sub!(/(RUNNER_USER=)(.*)/, '\1')
          line.sub!(/(RUNNER_LOG_DIR=)(.*)/, '\1' + log.to_s)
          line.sub!(/(PIPE_DIR=)(.*)/, '\1' + pipe.to_s)
          line.sub!(/(PLATFORM_DATA_DIR=)(.*)/, '\1' + data.to_s)
          line.sub!('grep "$RUNNER_BASE_DIR/.*/[b]eam"', 'grep "$RUNNER_ETC_DIR/app.config"')
          if line.strip == "RUNNER_BASE_DIR=${RUNNER_SCRIPT_DIR%/*}"
            line = "RUNNER_BASE_DIR=#{source.parent.to_s}\n"
          end
          f.write line
        end
      end
      target.chmod 0755
    end

    def write_manifest
      # TODO: For now this only saves the information that was used when
      # configuring the node. Later we'll verify/warn if the settings
      # used differ on subsequent generations.
      @configuration[:env] = @env
      @configuration[:vm] = @vm
      manifest.open('w') {|f| YAML.dump(@configuration, f) }
    end

    def touch_ssl_distribution_args
      # To make sure that the ssl_distribution.args file is present,
      # the control script in the source node has to have been run at
      # least once. Running the `chkconfig` command is innocuous
      # enough to accomplish this without other side-effects.
      `#{(source + control_script.basename).to_s} chkconfig`
    end
  end
end
