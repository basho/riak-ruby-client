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

        # "repeated" elements with zero items are indistinguishable
        # from a nil, so we have to manage has_precommit/has_postcommit
        # flags.
        def precommit=(newval)
          @precommit = newval
          @has_precommit = !!newval
        end

        def has_precommit=(newval)
          @has_precommit = newval
          @precommit ||= [] if newval
        end

        def postcommit=(newval)
          @postcommit = newval
          @has_postcommit = !!newval
        end

        def has_postcommit=(newval)
          @has_postcommit = newval
          @postcommit ||= [] if newval
        end
      end
    end
  end
end
