class Riak::Client::BeefcakeProtobuffsBackend
  class Operator
    attr_reader :backend

    def initialize(backend)
      @backend = backend
    end
  end
end
