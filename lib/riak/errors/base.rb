module Riak

  # Superclass for all errors raised by riak-client. If you catch an error
  # that the client raises that isn't descended from this class, please
  # file a bug. Thanks!
  class Error < StandardError
    include Util::Translation
  end
end
