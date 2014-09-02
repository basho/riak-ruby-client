require 'rubygems'
require 'rubygems/package_task'
require 'yard'
require 'rspec/core'
require 'rspec/core/rake_task'

def gemspec
  $riakclient_gemspec ||= Gem::Specification.load("riak-client.gemspec")
end

Gem::PackageTask.new(gemspec) do |pkg|
  pkg.need_zip = false
  pkg.need_tar = false
end

YARD::Rake::YardocTask.new :doc do |doc|
  doc.options = ["--markup markdown",
                 "--markup-provider=kramdown",
                 "--charset utf-8",
                 '-',
                 'lib/**/*.rb',
                 '*.md',
                 '*.markdown'
                 ].map{|e| e.split(' ')}.flatten
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


desc "Generate Protocol Buffers message definitions from riak_pb"
task :pb_defs => 'beefcake:pb_defs'

namespace :beefcake do
  task :pb_defs => 'lib/riak/client/beefcake/messages.rb'

  PROTO_FILES = %w{riak_kv riak_search riak_yokozuna riak_dt}
  PROTO_TMP = PROTO_FILES.map{|f| "tmp/#{f}.pb.rb"}
  
  task :clean do
    sh "rm -rf tmp/riak_pb"
    sh "rm -rf #{PROTO_TMP.join ' '}"
  end

  
  file 'lib/riak/client/beefcake/messages.rb' => PROTO_TMP do |t|
    sh "cat lib/riak/client/beefcake/header tmp/riak.pb.rb #{t.prerequisites.join ' '} lib/riak/client/beefcake/footer > #{t.name}"
  end

  PROTO_FILES.each do |f|
    file "tmp/#{f}.pb.rb" => 'tmp/riak_pb' do |t|
      sh "protoc --beefcake_out tmp -I tmp/riak_pb/src tmp/riak_pb/src/#{f}.proto"
    end
  end

  directory 'tmp/riak_pb' do
    cd 'tmp' do
      sh "git clone -b develop https://github.com/basho/riak_pb.git"
    end
  end
end
