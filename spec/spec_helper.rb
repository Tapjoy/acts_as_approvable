require 'rspec'
require 'active_record'
require 'timecop'
require 'shoulda/matchers'

require File.expand_path('../lib/acts_as_approvable', File.dirname(__FILE__))

require File.expand_path('support/database', File.dirname(__FILE__))
LOGGER = Support::Database.setup_log unless defined?(LOGGER)
Support::Database.load_schema

require File.expand_path('support/models', File.dirname(__FILE__))
require File.expand_path('support/matchers', File.dirname(__FILE__))

RSpec.configure do |config|
  config.around(:each) do |example|
    ActiveRecord::Base.transaction do
      example.run

      raise ActiveRecord::Rollback
    end
  end

  config.before(:each) do
    freeze_at = Time.parse('2012-01-01')
    Timecop.freeze(freeze_at)
  end

  config.after(:each) do
    Timecop.return
  end
end
