$:.push File.expand_path("../lib", __FILE__)
require 'riak/version'

Gem::Specification.new do |gem|
  # Meta
  gem.name = "riak-client"
  gem.version = Riak::VERSION
  gem.summary = %Q{riak-client is a rich client for Riak, the distributed database by Basho.}
  gem.description = %Q{riak-client is a rich client for Riak, the distributed database by Basho. It supports the full HTTP and Protocol Buffers interfaces including storage operations, bucket configuration, link-walking, secondary indexes and map-reduce.}
  gem.email = ["sean@basho.com"]
  gem.homepage = "http://github.com/basho/riak-ruby-client"
  gem.authors = ["Sean Cribbs"]

  # Deps
  gem.add_development_dependency "rspec", "~>2.10.0"
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
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  # gem.executables   = `git ls-files -- bin/*`.split("\n")

  gem.require_paths = ['lib']
end
