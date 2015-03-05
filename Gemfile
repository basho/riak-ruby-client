source "https://rubygems.org"

gemspec

group :guard do
  gem 'guard-rspec'
  gem 'rb-fsevent'
  gem 'terminal-notifier-guard'
end

platforms :mri do
  gem 'yajl-ruby'
end

platforms :jruby, :rbx do
  gem 'json'
end

gem 'beefcake', '1.1.0.pre1'
