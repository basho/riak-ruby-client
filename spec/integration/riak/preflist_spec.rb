require 'spec_helper'
require 'riak'

describe 'Preflist', integration: true, test_client: true do
  let(:bucket){ random_bucket }
  let(:robject) do
    bucket.get_or_new(random_key).tap do |robj|
      robj.data = 'asdf'
      robj.store
    end
  end

  matcher :be_a_preflist do
    match do |actual|
      actual.is_a?(Array) &&
      actual.first.is_a?(Riak::PreflistItem)
    end
  end

  it 'is available from RObjects' do
    expect(robject.preflist).to be_a_preflist
  end

  it 'is available from Buckets' do
    expect(bucket.get_preflist robject.key).to be_a_preflist
  end

  it 'is available from the Client' do
    expect(test_client.get_preflist bucket.name, robject.key).to be_a_preflist
  end
end
