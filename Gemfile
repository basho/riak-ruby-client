source :rubygems

gem 'i18n', '>=0.4.0'
gem 'builder', '>= 2.1.2'
gem 'beefcake', '~>0.3.7'
gem 'multi_json', '~>1.0'
gem 'innertube', '~>1.0.2'

group :development do
  gem 'rspec', '~>2.10.0'
  gem 'fakeweb', '>=1.2'
  gem 'rack', '>=1.0'
  gem 'excon', '>=0.6.1'
  gem 'rake'
end

group :guard do
  gem 'guard-rspec'
  gem 'rb-fsevent'
  gem 'growl'
end

platforms :mri do
  gem 'yajl-ruby', :groups => [:development, :guard]
end

platforms :jruby do
  gem 'jruby-openssl', :groups => [:development, :guard]
end

platforms :jruby, :rbx do
  gem 'json', :groups => [:development, :guard]
end
# platforms :mri_18, :jruby do
#   gem 'ruby-debug'
# end

# platforms :mri_19 do
#   gem 'ruby-debug19'
# end
