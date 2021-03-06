# Copyright 2010-present Basho Technologies, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'benchmark'
require 'yaml'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'riak'
# require 'riak/test_server'

puts "Ruby #{RUBY_VERSION} #{RUBY_PLATFORM}"
puts Time.now.to_s

count = ENV['MULTIGET_COUNT'].to_i
puts "Count #{count}"

threads = ENV['MULTIGET_THREADS'].to_i
puts "Threads #{threads}"

# config = YAML.load_file(File.expand_path("../../spec/support/test_server.yml", __FILE__))

cluster = (1..4).map do |n|
  {host: '10.0.38.132', http_port: "100#{n}8" }
end

client = Riak::Client.new nodes: cluster
client.multiget_threads = threads

bucket = client.bucket 'mooltiget'

keys = (0..count).map(&:to_s)

# puts "Inserting #{count} key value pairs"
# 
# keys.each do |n|
#   if n % 100 == 0
#     print "\r#{n}"
#   end
#   obj = bucket.get_or_new n.to_s
#   obj.content_type = 'text/plain'
#   obj.data = n.to_s
#   obj.store
# end

# puts "waiting"

# sleep 10

puts "benchmarking"

Benchmark.bmbm do |x|
  x.report 'individual' do
    keys.each {|k| bucket[k]}
  end

  x.report 'multiget' do
    bucket.get_many keys
  end
end

# puts "deleting #{count} key value pairs"

# keys.each do |k|
#   bucket.delete k
# end

puts
