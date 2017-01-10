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

module Riak
  class Client
    def create_search_index(name, schema = nil, n_val = nil, timeout = nil)
      raise ArgumentError, t("zero_length_index") if name.nil? || name.empty?
      backend do |b|
        b.create_search_index(name, schema, n_val, timeout)
      end
      true
    end

    def get_search_index(name)
      raise ArgumentError, t("zero_length_index") if name.nil? || name.empty?
      resp = []
      backend do |b|
        resp = b.get_search_index(name)
      end
      resp.index && Array === resp.index ? resp.index.first : resp
    end

    def list_search_indexes()
      resp = []
      backend do |b|
        resp = b.get_search_index(nil)
      end
      resp.index ? resp.index : resp
    end

    def delete_search_index(name)
      raise ArgumentError, t("zero_length_index") if name.nil? || name.empty?
      backend do |b|
        b.delete_search_index(name)
      end
      true
    end

    def create_search_schema(name, content)
      raise ArgumentError, t("zero_length_schema") if name.nil? || name.empty?
      raise ArgumentError, t("zero_length_content") if content.nil? || content.empty?
      backend do |b|
        b.create_search_schema(name, content)
      end
      true
    end

    def get_search_schema(name)
      raise ArgumentError, t("zero_length_schema") if name.nil? || name.empty?
      backend do |b|
        return b.get_search_schema(name)
      end
    end
  end
end
