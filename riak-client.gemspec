$:.push File.expand_path("../lib", __FILE__)
require 'riak/version'

Gem::Specification.new do |gem|
  # Meta
  gem.name = "riak-client"
  gem.version = Riak::VERSION
  gem.summary = %Q{riak-client is a rich client for Riak, the distributed database by Basho.}
  gem.description = %Q{riak-client is a rich client for Riak, the distributed database by Basho. It supports the full HTTP and Protocol Buffers interfaces including storage operations, bucket configuration, link-walking, secondary indexes and map-reduce.}
  gem.email = ['bryce@basho.com']
  gem.homepage = "http://github.com/basho/riak-ruby-client"
  gem.authors = ['Bryce Kerley']
  gem.license = 'Apache 2.0'

  gem.required_ruby_version = '>= 1.9.3'

  # Deps
  gem.add_development_dependency "rspec", "~> 3.0"
  gem.add_development_dependency 'rake', '~> 10.1.1'
  gem.add_development_dependency 'yard', '~> 0.8.7'
  gem.add_development_dependency 'kramdown', '~> 1.4'
  gem.add_development_dependency 'simplecov', '~> 0.10.0'
  gem.add_development_dependency "instrumentable", "~> 1.1.0"
  gem.add_development_dependency "rubocop", "~> 0.28.0"

  gem.add_runtime_dependency "activesupport", ">= 3.2.0"
  gem.add_runtime_dependency "i18n", ">=0.6.8"
  gem.add_runtime_dependency "beefcake", "~> 1.1"
  gem.add_runtime_dependency "multi_json", "~>1.0"
  gem.add_runtime_dependency "innertube", "~>1.0.2"
  gem.add_runtime_dependency 'cert_validator', '~> 0.0.1'

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
