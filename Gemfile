source "https://rubygems.org"

gemspec
gem 'bundler'
gem 'rake'

gem 'beefcake', github: 'protobuf-ruby/beefcake', branch: 'bk-encode-frozen-string'

group :guard do
  gem 'guard-rspec'
  gem 'rb-fsevent'
  gem 'growl'
end

platforms :mri do
  gem 'yajl-ruby'
end

platforms :jruby do
  gem 'jruby-openssl'
end

platforms :jruby, :rbx do
  gem 'json'
end
