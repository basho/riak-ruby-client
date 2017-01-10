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
    # @private
    class BeefcakeProtobuffsBackend
      class RpbIndexReq
        module IndexQueryType
          EQ = 0
          RANGE = 1
        end
      end

      class RpbBucketKeyPreflistItem
        include Riak::PreflistItem
      end

      class RpbBucketProps

        # "repeated" elements with zero items are indistinguishable
        # from a nil, so we have to manage has_precommit/has_postcommit
        # flags.
        def precommit=(newval)
          newval = clean_hook newval
          @precommit = newval
          @has_precommit = !!newval
        end

        def has_precommit=(newval)
          @has_precommit = newval
          @precommit ||= [] if newval
        end

        def postcommit=(newval)
          newval = clean_hook newval
          @postcommit = newval
          @has_postcommit = !!newval
        end

        def has_postcommit=(newval)
          @has_postcommit = newval
          @postcommit ||= [] if newval
        end

        def chash_keyfun=(newval)
          @chash_keyfun = clean_modfun newval
        end

        def linkfun=(newval)
          @linkfun = clean_modfun newval
        end

        private

        def clean_hook(newval)
          if newval.is_a? Array
            return newval.map{|v| clean_hook v}
          end

          newval = newval.symbolize_keys if newval.is_a? Hash
          if newval.is_a?(Hash) && newval[:module] && newval[:function]
            modfun = RpbModFun.new newval
            hook = RpbCommitHook.new modfun: modfun
            newval = hook
          elsif newval.is_a?(Hash) && newval[:name]
            hook = RpbCommitHook.new newval
            newval = hook
          elsif newval.is_a? String
            hook = RpbCommitHook.new name: newval
            newval = hook
          end

          return newval
        end

        def clean_modfun(newval)
          return newval unless newval.is_a? Hash

          newval = newval.symbolize_keys
          if newval[:mod] && newval[:fun]
            modfun = RpbModFun.new :'module' => newval[:mod], function: newval[:fun]
          end

          return modfun
        end
      end
    end
  end
end
