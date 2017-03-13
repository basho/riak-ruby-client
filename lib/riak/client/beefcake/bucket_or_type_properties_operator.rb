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

class Riak::Client::BeefcakeProtobuffsBackend
  class BucketOrTypePropertiesOperator
    attr_reader :backend

    QUORUMS = Riak::Client::ProtobuffsBackend::QUORUMS

    def initialize(backend)
      @backend = backend
    end

    def get_properties(_bucket_or_type, _options = {})
      raise NotImplementedError
    end

    def get(bucket_or_type, options = {})
      response = get_properties(bucket_or_type, options)
      properties = response.props.to_hash.stringify_keys
      return rubyfy(properties)
    end

    def put_properties(_bucket_or_type, _properties = {}, _options = {})
      raise NotImplementedError
    end

    def put(bucket_or_type, props = {}, options = {})
      properties = riakify props
      put_properties(bucket_or_type, properties, options)
    end

    private
    def rubyfy(received_properties)
      props = received_properties.dup

      rubyfy_quorums(props)
      rubyfy_hooks(props)
      rubyfy_modfuns(props)

      return props
    end

    def riakify(requested_properties)
      props = requested_properties.stringify_keys

      riakify_quorums(props)
      riakify_hooks(props)
      riakify_modfuns(props)
      riakify_repl_mode(props)

      return props
    end

    def rubyfy_quorums(props)
      %w{r pr w pw dw rw}.each do |k|
        next unless props[k]
        next unless QUORUMS.values.include? props[k]

        props[k] = QUORUMS.invert[props[k]]
      end
    end

    def riakify_quorums(props)
      %w{r pr w pw dw rw}.each do |k|
        next unless props[k]
        v = props[k].to_s
        next unless QUORUMS.keys.include? v

        props[k] = QUORUMS[v]
      end
    end

    def rubyfy_hooks(props)
      %w{precommit postcommit}.each do |k|
        next unless props[k]
        props[k] = props[k].map do |v|
          next v[:name] if v[:name]
          rubyfy_modfun(v[:modfun])
        end
      end
    end

    def riakify_hooks(props)
      %w{precommit postcommit}.each do |k|
        v = props[k]
        next unless v
        props[k] =
          if v.is_a? Array
            v.map{ |e| riakify_single_hook(e) }
          else
            [riakify_single_hook(v)]
          end
      end
    end

    def riakify_single_hook(hook)
      message = RpbCommitHook.new

      if hook.is_a? String
        message.name = hook
      elsif hook['name']
        message.name = hook['name']
      else
        message.modfun = riakify_modfun(hook)
      end
      return message
    end

    def rubyfy_modfuns(props)
      %w{chash_keyfun linkfun}.each do |k|
        next if props[k].nil?
        props[k] = rubyfy_modfun(props[k])
      end
    end

    def riakify_modfuns(props)
      %w{chash_keyfun linkfun}.each do |k|
        next if props[k].nil?
        props[k] = riakify_modfun(props[k])
      end
    end

    def rubyfy_modfun(modfun)
      {
        'mod' => modfun[:module],
        'fun' => modfun[:function]
      }
    end

    def riakify_modfun(modfun)
      m = modfun.stringify_keys
      RpbModFun.new(module: m['mod'], function: m['fun'])
    end

    def riakify_repl_mode(props)
      return unless props['repl'].is_a? Symbol

      props['repl'] = case props['repl']
                      when :false
                        0
                      when :realtime
                        1
                      when :fullsync
                        2
                      when :true
                        3
                      end
    end
  end
end
