require 'riak/util/translation'

module Riak
  # Raised when a tombstone object (i.e. has vclock, but no rcontent values) is
  # stored or manipulated as if it had a single value.
  class Tombstone < StandardError
    include Util::Translation

    def initialize(robject)
      super t('tombstone_object', :robject => robject.inspect)
    end
  end
end
