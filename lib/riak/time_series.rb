module Riak

  # Container module for Riak Time Series features.
  module TimeSeries
  end
end

require 'riak/errors/time_series'

require 'riak/time_series/deletion'
require 'riak/time_series/query'
require 'riak/time_series/submission'
require 'riak/time_series/read'
