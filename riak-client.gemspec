$:.push File.expand_path("../lib", __FILE__)
require 'riak/version'

Gem::Specification.new do |gem|
  # Meta
  gem.name = "riak-client"
  gem.version = Riak::VERSION
  gem.summary = %Q{riak-client is a rich client for Riak, the distributed database by Basho.}
  gem.description = %Q{riak-client is a rich client for Riak, the distributed database by Basho. It supports the full HTTP and Protocol Buffers interfaces including storage operations, bucket configuration, link-walking, secondary indexes and map-reduce.}
  gem.email = ["sean@basho.com", 'bryce@basho.com']
  gem.homepage = "http://github.com/basho/riak-ruby-client"
  gem.authors = ["Sean Cribbs", 'Bryce Kerley']
  gem.license = 'Apache 2.0'

  # Deps
  gem.add_development_dependency "rspec", "~>2.13.0"
  gem.add_development_dependency "fakeweb", ">=1.2"
  gem.add_development_dependency "rack", ">=1.0"
  gem.add_development_dependency "excon", ">=0.6.1"
  gem.add_development_dependency 'rake'
  gem.add_runtime_dependency "i18n", ">=0.4.0"
  gem.add_runtime_dependency "builder", ">= 2.1.2"
  gem.add_runtime_dependency "beefcake", "~>0.3.7"
  gem.add_runtime_dependency "multi_json", "~>1.0"
  gem.add_runtime_dependency "innertube", "~>1.0.2"

  # Files

  # NOTE: This section must be manually kept in sync with the
  # .gitignore file, but should not normally need to be modified
  # unless new top-level files or directory trees are being added.
  includes = %W{
    lib/**/*
    spec/**/*
    Gemfile
    Rakefile
    Guardfile
    LICENSE*
    RELEASE_NOTES*
    README*
    erl_src/*
    .gitignore
    .document
    .rspec
    riak-client.gemspec
  }

  excludes = %W{
    **/*.swp
    **/#*
    **/.#*
    **/*~
    **/*.rbc
    **/.DS_Store
    spec/support/test_server.yml
    .ruby-version
  }

  files = includes.map {|glob| Dir[glob] }.flatten.select {|f| File.file?(f) }.sort
  files.reject! {|f| excludes.any? {|e| File.fnmatch?(e, f) } }

  gem.files = files
  gem.test_files = files.grep(/^spec/)
  gem.require_paths = ['lib']
end
