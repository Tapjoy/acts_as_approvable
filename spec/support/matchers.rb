require 'rspec/expectations'

RSpec::Matchers.define :extend do |expected|
  match do |actual|
    actual.included_modules.include?(expected)
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
