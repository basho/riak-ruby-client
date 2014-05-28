require 'riak/errors/base'
module Riak
  class ProtobuffsError < Error
  end

  class ProtobuffsFailedHeader < ProtobuffsError
    def initialize
      super t('pbc.failed_header')
    end
  end
end
