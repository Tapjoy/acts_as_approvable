require 'rspec/expectations'
require 'shoulda/active_record/matchers'

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

RSpec::Matchers.define :be_an_options_array do
  match do |actual|
    actual.should be_an(Array)
    actual.each do |option|
      unless option.is_a?(String)
        option.should be_an(Array)
        option.length.should be(2)
      end
    end
  end
  description do
    'returns an array usable by #options_for_select'
  end
  failure_message_for_should do |actual|
    "expected #{actual} to map to a valid #options_for_select array"
  end
  failure_message_for_should_not do |actual|
    "expected #{actual} not to map to a valid #options_for_select array"
  end
end

module Shoulda
  module ActiveRecord
    module Matchers
      def validate_inclusion_of(attr)
        ValidatesInclusionOfMatcher.new(attr)
      end

      class ValidatesInclusionOfMatcher < ValidationMatcher
        def in(values)
          @values = values
          self
        end

        def description
          "require #{@attribute} to be one of #{@values.inspect}"
        end

        def matches?(subject)
          super(subject)

          allows_given_values && disallows_other_values
        end

        private
        def allows_given_values
          @values.each do |value|
            allows_value_of(value, @message)
          end unless @values.empty?
        end

        def disallows_other_values
          @values.each do |value|
            disallows_value_of("#{value}s", @message)
          end unless @values.empty?
        end
      end
    end
  end
end
