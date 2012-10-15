require 'riak/util/translation'

module Riak
  # Raised when an object that is in conflict (i.e. has siblings) is
  # stored or manipulated as if it had a single value.
  class Conflict < StandardError
    include Util::Translation

    def initialize(robject)
      super t('object_in_conflict', :object => robject.inspect)
    end
  end
end
