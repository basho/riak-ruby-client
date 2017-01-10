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
  module Serializers
    include Util::Translation
    extend self

    def [](content_type)
      serializers[content_type]
    end

    def []=(content_type, serializer)
      serializers[content_type] = serializer
    end

    def serialize(content_type, content)
      serializer_for(content_type).dump(content)
    end

    def deserialize(content_type, content)
      serializer_for(content_type).load(content)
    end

    private

    def serializer_for(content_type)
      serializers.fetch(content_type[/^[^;\s]+/]) do
        raise IOError.new(t('serializer_not_implemented', :content_type => content_type.inspect))
      end
    end

    def serializers
      @serializers ||= {}
    end

    module TextPlain
      extend self

      def dump(object)
        object.to_s
      end

      def load(string)
        string
      end
    end

    module ApplicationJSON
      extend self

      def dump(object)
        object.to_json(Riak.json_options)
      end

      def load(string)
        Riak::JSON.parse(string)
      end
    end

    Serializers['text/plain'] = TextPlain
    Serializers['application/json'] = ApplicationJSON
    Serializers['application/x-ruby-marshal'] = ::Marshal

    YAML_MIME_TYPES = %w[
      text/yaml
      text/x-yaml
      application/yaml
      application/x-yaml
    ]

    YAML_MIME_TYPES.each do |mime_type|
      Serializers[mime_type] = ::YAML
    end
  end
end
