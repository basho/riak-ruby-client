require 'riak/errors/base'

module Riak
  class BackendCreationError < Error
    def initialize(backend)
      super t('protobuffs_configuration', backend: backend)
    end
  end
end
