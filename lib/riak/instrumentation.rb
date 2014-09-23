begin
  require 'instrumentable'
  require 'riak/client/instrumentation'
rescue LoadError => e
  # Go quietly into the night...(?)
end
