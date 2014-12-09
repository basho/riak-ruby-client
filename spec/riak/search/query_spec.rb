require 'spec_helper'

describe Riak::Search::Query do
  it 'creates query objects with a client, index, and query string'
  it 'creates query objects with a client, index name, and query string'
  it 'errors when querying with a non-existent index'
  it 'allows specifying other query options on creation'
  it 'allows specifying query options with accessors'
  it 'returns a ResultCollection'
end
