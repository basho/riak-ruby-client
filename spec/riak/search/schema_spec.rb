require 'spec_helper'
require 'riak/search/schema'

describe Riak::Search::Schema do
  it 'creates schema objects with a client and schema name'
  it 'tests for schema existence'
  it 'permits schema creation'
  it 'raises an error when creating a schema that already exists'
  it 'returns data about the schema'
end
