require 'spec_helper'
require 'timeout'

describe 'Protocol Buffers', test_client: true do
  describe 'interrupted requests' do

    let(:bucket){ random_bucket 'interrupted_requests' }
    
    before do
      first = bucket.new 'first'
      first.data = 'first'
      first.content_type = 'text/plain'
      first.store

      second = bucket.new 'second'
      second.data = 'second'
      second.content_type = 'text/plain'
      second.store
    end

    it 'fails out when a request is interrupted, and never returns the wrong payload' do
      expect do
        Timeout.timeout 1 do
          loop do
            expect(bucket.get('first').data).to eq 'first'
          end
        end
      end.to raise_error Timeout::Error

      expect(bucket.get('second').data).to eq 'second'
    end    
  end
end
