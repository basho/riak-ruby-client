require 'spec_helper'

describe Riak::Search::Index do
  it 'creates index objects with a client and index name'
  it 'tests for index existence'
  it 'permits index creation'
  it 'raises an error when creating an index that already exists'
  it 'returns data about the index'
end
