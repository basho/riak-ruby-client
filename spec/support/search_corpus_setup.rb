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

# encoding: utf-8
shared_context "search corpus setup" do
  before do
    @search_bucket = random_bucket 'search_test'
    @backend.create_search_index @search_bucket.name

    wait_until{ !@backend.get_search_index(@search_bucket.name).nil? }

    @client.set_bucket_props(@search_bucket,
                             {search_index: @search_bucket.name},
                             'yokozuna')

    wait_until do
      p = @client.get_bucket_props(@search_bucket, type: 'yokozuna')
      p['search_index'] == @search_bucket.name
    end

    idx = 0
    old_encoding = Encoding.default_external
    Encoding.default_external = Encoding::UTF_8
    IO.foreach("spec/fixtures/bitcask.txt") do |para|
      next if para =~ /^\s*$|introduction|chapter/ui
      idx += 1
      Riak::RObject.new(@search_bucket, "bitcask-#{idx}") do |obj|
        obj.content_type = 'text/plain'
        obj.raw_data = para
        @backend.store_object(obj, type: 'yokozuna')
      end
    end
    Encoding.default_external = old_encoding

    wait_until do
      results = @backend.search(@search_bucket.name,
                                'contain your entire keyspace',
                                df: 'text')
      results['docs'].length > 0
    end
  end
end
