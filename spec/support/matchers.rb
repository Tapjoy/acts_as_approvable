require 'rspec/expectations'

class Module
  # Return any modules we +extend+
  def extended_modules
    (class << self; self end).included_modules
  end
end

# Truthfully this checks both extend *and* include. :include is already used as a matcher for Arrays :-/
RSpec::Matchers.define :extend do |expected|
  match do |actual|
    extended = (actual.extended_modules - Module.extended_modules) + actual.included_modules
    extended.include?(expected)
  end
  description do
    "extend #{expected}"
  end
  failure_message_for_should do |actual|
    "expected #{actual} to extend #{expected}"
  end
  failure_message_for_should_not do |actual|
    "expected #{actual} not to extend #{expected}"
  end
end
