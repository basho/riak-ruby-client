require 'rubygems'
require 'rubygems/package_task'
require 'rspec/core'
require 'rspec/core/rake_task'

def gemspec
  $riakclient_gemspec ||= Gem::Specification.load("riak-client.gemspec")
end

Gem::PackageTask.new(gemspec) do |pkg|
  pkg.need_zip = false
  pkg.need_tar = false
end

task :gem => :gemspec

desc %{Validate the gemspec file.}
task :gemspec do
  gemspec.validate
end

desc %{Release the gem to RubyGems.org}
task :release => :gem do
  system "gem push pkg/#{gemspec.name}-#{gemspec.version}.gem"
end

desc "Cleans up white space in source files"
task :clean_whitespace do
  no_file_cleaned = true

  Dir["**/*.rb"].each do |file|
    contents = File.read(file)
    cleaned_contents = contents.gsub(/([ \t]+)$/, '')
    unless cleaned_contents == contents
      no_file_cleaned = false
      puts " - Cleaned #{file}"
      File.open(file, 'w') { |f| f.write(cleaned_contents) }
    end
  end

  if no_file_cleaned
    puts "No files with trailing whitespace found"
  end
end

desc "Run Unit Specs Only"
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = %w[--profile --tag ~integration --tag ~slow]
end

namespace :spec do
  desc "Run Integration Specs Only (without explicitly slow specs)"
  RSpec::Core::RakeTask.new(:integration) do |spec|
    spec.rspec_opts = %w[--profile --tag '~slow' --tag integration]
  end

  desc "Run All Specs (without explicitly slow specs)"
  RSpec::Core::RakeTask.new(:all) do |spec|
    spec.rspec_opts = %w[--profile --tag '~slow']
  end

  desc "Run Slow Specs Only"
  RSpec::Core::RakeTask.new(:slow) do |spec|
    spec.rspec_opts = %w[--profile --tag slow]
  end
end

desc "Run All Specs (including slow specs)"
RSpec::Core::RakeTask.new(:ci) do |spec|
  spec.rspec_opts = %w[--profile]
end

task :default => :ci
