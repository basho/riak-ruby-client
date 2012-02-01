# Emulates the QuickCheck ?SOMETIMES macro.

RSpec.configure do |config|
  config.around(:each, :max_retries => lambda { |m| !!m }) do |example|
    retries = example.metadata[:max_retries]
    begin
      example.run
    rescue => e
      retries -= 1
      retry if retries >= 0
      raise
    end
  end
end

RSpec::Core::ExampleGroup.define_example_method :sometimes, :max_retries => 3
