require 'riak/core_ext/deep_dup'

module Riak
  class Node
    # Settings based on Riak 1.1.
    ENV_DEFAULTS = {
      :riak_api => {
      },
      :riak_core => {
        :ring_creation_size => 64
      },
      :riak_kv => {
        :storage_backend => :riak_kv_bitcask_backend,
        :map_js_vm_count => 8,
        :reduce_js_vm_count => 6,
        :hook_js_vm_count => 2,
        :mapper_batch_size => 5,
        :js_max_vm_mem => 8,
        :js_thread_stack => 16,
        :riak_kv_stat => true,
        :legacy_stats => true,
        :vnode_vclocks => true,
        :http_url_encoding => :on,
        :legacy_keylisting => false,
        :mapred_system => :pipe,
        :mapred_2i_pipe => true,
        :listkeys_backpressure => true,
        :add_paths => []
      },
      :riak_search => {
        :enabled => true
      },
      :luwak => {
        :enabled => true
      },
      :merge_index => {
        :buffer_rollover_size => 1048576,
        :max_compact_segments => 20
      },
      :eleveldb => {},
      :bitcask => {},
      :lager => {
        :crash_log_size => 10485760,
        :crash_log_msg_size => 65536,
        :crash_log_date => "$D0",
        :crash_log_count => 5,
        :error_logger_redirect => true
      },
      :riak_sysmon => {
        :process_limit => 30,
        :port_limit => 30,
        :gc_ms_limit => 100,
        :heap_word_limit => 40111000,
        :busy_port => true,
        :busy_dist_port => true
      },
      :sasl => {
        :sasl_error_logger => false
      },
      :riak_control => {
        :enabled => false,
        :auth => :userlist,
        :userlist => {"user" => "pass"},
        :admin => true
      }
    }.freeze

    # Based on Riak 1.1.
    VM_DEFAULTS = {
      "+K" => true,
      "+A" => 64,
      "-smp" => "enable",
      "+W" => "w",
      "-env ERL_MAX_PORTS" => 4096,
      "-env ERL_FULLSWEEP_AFTER" => 0
    }.freeze

    protected
    # Populates the defaults
    def set_defaults
      @env = ENV_DEFAULTS.deep_dup
      @vm = VM_DEFAULTS.deep_dup
    end
  end
end
