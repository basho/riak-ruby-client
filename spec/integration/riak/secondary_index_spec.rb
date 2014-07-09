require 'spec_helper'

describe 'Secondary indexes', test_client: true, integration: true do
  let(:bucket){ random_bucket '2i-integration' }
  let(:backend){ Riak::Client::BeefcakeProtobuffsBackend.new(test_client, test_client.nodes.first) }
  before do
    50.times do |i|
      bucket.new(i.to_s).tap do |obj|
        obj.indexes["index_int"] << i
        obj.indexes["index_bin"] << i.to_s
        obj.data = [i]
        backend.store_object(obj)
      end
    end
  end

  it "finds keys for an equality query" do
    expect(backend.get_index(bucket.name, 'index_int', 20)).to eq(["20"])
  end

  it "finds keys for a range query" do
    expect(backend.get_index(bucket.name, 'index_int', 19..21)).to match_array(["19","20", "21"])
  end

  it "returns an empty array for a query that does not match any keys" do
    expect(backend.get_index(bucket.name, 'index_int', 10000)).to eq([])
  end

  it "returns terms" do
    results = nil
    expect do
      results = backend.get_index(bucket.name, 
                                  'index_int', 
                                  19..21, 
                                  return_terms: true)
    end.to_not raise_error

    expect(results).to be_a Array
    expect(results.with_terms).to be_a Hash
  end

  it "returns terms matching a term_regex" do
    results = nil
    expect do
      results = backend.get_index(bucket.name, 
                                  'index_bin', 
                                  '19'..'21', 
                                  return_terms: true,
                                  term_regex: '20')
    end.to_not raise_error

    terms = results.with_terms

    expect(terms['20']).to be
    expect(terms['19']).to be_empty
  end
end
