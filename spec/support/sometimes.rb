# Emulates the QuickCheck ?SOMETIMES macro.

module Sometimes
  def run_with_retries(example_to_run, retries)
    self.example.metadata[:retries] ||= retries
    retries.times do |t|
      self.example.metadata[:retried] = t + 1
      self.example.instance_variable_set(:@exception, nil)
      example_to_run.run
      break unless self.example.exception
    end
    if e = self.example.exception
      new_exception = e.exception(e.message + "[Retried #{retries} times]")
      new_exception.set_backtrace e.backtrace
      self.example.instance_variable_set(:@exception, new_exception)
    end
  end
end

RSpec.configure do |config|
  config.include Sometimes
  config.alias_example_to :sometimes, :sometimes => true
  config.add_setting :sometimes_retry_count, :default => 3

  config.around(:each, :sometimes => true) do |example|
    retries = example.metadata[:retries] || RSpec.configuration.sometimes_retry_count
    run_with_retries(example, retries)
  end

  config.after(:suite) do
    formatter = RSpec.configuration.formatters.first
    color = lambda {|tint, msg| formatter.send(tint, msg) }
    retried_examples = RSpec.world.example_groups.map do |g|
      g.descendants.map do |d|
        d.filtered_examples.select {|e| e.metadata[:sometimes] && e.metadata[:retried] > 1 }
      end
    end.flatten
    formatter.message color[retried_examples.empty? ? :success_color : :pending_color, "\n\nRetried examples: #{retried_examples.count}"]
    unless retried_examples.empty?
      retried_examples.each do |e|
        formatter.message "  #{e.full_description}"
        formatter.message(color[:pending_color, "  [#{e.metadata[:retried]}/#{e.metadata[:retries]}] "] + RSpec::Core::Metadata::relative_path(e.location))
      end
    end
  end
end
