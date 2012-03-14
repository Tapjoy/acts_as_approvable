if RUBY_VERSION =~ /^1\.9/
  begin
    require 'simplecov'
    SimpleCov.start do
      add_filter '/spec/'
    end if ENV['COVERAGE']
  rescue LoadError
  end
end

ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..'))

require 'rspec'
require 'shoulda'
require 'timecop'
require 'active_record'

begin
  require 'plymouth'
rescue LoadError
end

require File.expand_path('../lib/acts-as-approvable', File.dirname(__FILE__))

require File.expand_path('support/database', File.dirname(__FILE__))
require File.expand_path('support/models', File.dirname(__FILE__))
require File.expand_path('support/matchers', File.dirname(__FILE__))

RSpec.configure do |config|
  config.before(:suite) do
    LOGGER = Support::Database.setup_log unless defined?(LOGGER)
    Support::Database.load_schema
  end

  config.before(:each) do
    Object.send(:remove_const, :CleanApprovable) if defined?(CleanApprovable)
    class CleanApprovable < ActiveRecord::Base
      def self.table_name; 'nots'; end
      def self.primary_key; 'id'; end
    end

    freeze_at = Time.parse('2012-01-01')
    Timecop.freeze(freeze_at)
  end

  config.after(:each) do
    Timecop.return
    Support::Database.truncate
  end
end
