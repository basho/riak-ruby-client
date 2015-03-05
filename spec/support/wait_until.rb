# This module is used for search testing, and other testing activities that may
# take time to "settle" in Riak.
module WaitUntil
  def wait_until(attempts = 10)
    (0..attempts).each do |a|
      begin
        break if yield
      rescue
        nil
      end

      sleep a
    end
  end
end

RSpec.configure do |config|
  config.include WaitUntil
  config.extend WaitUntil
end
