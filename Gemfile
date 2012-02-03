source :rubygems

gemspec
gem 'bundler'

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

# platforms :mri_18, :jruby do
#   gem 'ruby-debug'
# end

# platforms :mri_19 do
#   gem 'ruby-debug19'
# end
