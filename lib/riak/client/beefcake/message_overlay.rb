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

      class RpbBucketProps
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
      end

      class RpbSearchDoc
        # rebuild the fields instance method  since the
        # generated :fields field overwrote this
        def fields
          self.class.fields
        end
        repeated :properties, RpbPair, 1
      end

    end
  end
end
