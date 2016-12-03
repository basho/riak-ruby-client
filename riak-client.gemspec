require './lib/riak/version'

Gem::Specification.new do |gem|
  # Meta
  gem.name = "riak-client"
  gem.version = Riak::VERSION
  gem.summary = %Q{riak-client is a rich client for Riak, the distributed database by Basho.}
  gem.description = %Q{#{gem.summary} It supports the full HTTP and Protocol Buffers interfaces including storage operations, bucket configuration, link-walking, secondary indexes and map-reduce.}
  gem.email = ['lbakken@basho.com']
  gem.homepage = "http://github.com/basho/riak-ruby-client"
  gem.authors = ['Bryce Kerley', 'Luke Bakken']
  gem.license = 'Apache-2.0'

  gem.required_ruby_version = '>= 1.9.3'

  # Deps
  gem.add_development_dependency 'activesupport', '~> 4.2'
  gem.add_development_dependency 'instrumentable', '~> 1.1'
  gem.add_development_dependency 'kramdown', '~> 1.4'
  gem.add_development_dependency 'rake', '~> 10.1'
  gem.add_development_dependency 'rspec', '~> 3.0'
  gem.add_development_dependency 'rubocop', '~> 0.40.0'
  gem.add_development_dependency 'simplecov', '~> 0.10'
  gem.add_development_dependency 'yard', '~> 0.8'

  gem.add_runtime_dependency 'beefcake', '~> 1.1'
  gem.add_runtime_dependency 'cert_validator', '~> 0.0.1'
  gem.add_runtime_dependency 'i18n', '~> 0.6'
  gem.add_runtime_dependency 'innertube', '~> 1.0'
  gem.add_runtime_dependency 'multi_json', '~> 1.0'

  gem.files = `git ls-files lib LICENSE.md README.md RELNOTES.md`.split($/)
end
