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
  failure_message do |actual|
    "expected #{actual} to extend #{expected}"
  end
  failure_message_when_negated do |actual|
    "expected #{actual} not to extend #{expected}"
  end
end

RSpec::Matchers.define :be_an_options_array do
  match do |actual|
    expect(actual).to be_an(Array)
    actual.each do |option|
      unless option.is_a?(String)
        expect(option).to be_an(Array)
        expect(option.length).to be(2)
      end
    end
  end
  description do
    'returns an array usable by #options_for_select'
  end
  failure_message do |actual|
    "expected #{actual} to map to a valid #options_for_select array"
  end
  failure_message_when_negated do |actual|
    "expected #{actual} not to map to a valid #options_for_select array"
  end
end
