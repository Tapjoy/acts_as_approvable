ENV['RAILS_ENV'] = 'test'

require 'rubygems'
require 'active_record'

require File.expand_path('../../lib/acts-as-approvable', File.dirname(__FILE__))

require File.expand_path('../../spec/support/database', File.dirname(__FILE__))
require File.expand_path('../../spec/support/models', File.dirname(__FILE__))

Before do
  LOGGER = Support::Database.setup_log unless defined?(LOGGER)
  Support::Database.load_schema
end
