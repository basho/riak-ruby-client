module WaitUntil
  def wait_until(attempts=10)
    (0..attempts).each do |a|
      break if yield rescue nil
      
      sleep a
    end
  end
end

RSpec.configure do |config|
  config.include WaitUntil
  config.extend WaitUntil
end
