if RUBY_VERSION =~ /^1\.9/
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
  end if ENV['COVERAGE']
end

ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..'))

require 'rubygems'
require 'rspec'
require 'shoulda'
require 'timecop'
require 'active_record'

require File.expand_path('../lib/acts-as-approvable', File.dirname(__FILE__))
require File.expand_path('support/models', File.dirname(__FILE__))
require File.expand_path('support/matchers', File.dirname(__FILE__))

logfile = File.expand_path('debug.log', File.dirname(__FILE__))
LOGGER = ActiveRecord::Base.logger = if defined?(ActiveSupport::BufferedLogger)
                                       ActiveSupport::BufferedLogger.new(logfile)
                                     else
                                       Logger.new(logfile)
                                     end

def load_schema
  config = YAML::load(IO.read(File.expand_path('database.yml', File.dirname(__FILE__))))

  unless db_adapter = ENV['DB']
    %w(sqlite3 mysql2 sqlite).each do |gem|
      begin
        require gem
        db_adapter = gem
        break
      rescue MissingSourceFile
      end
    end
  end

  if db_adapter.nil?
    raise 'No DB Adapter selected. Pass the DB= option to pick one, or install Sqlite or Sqlite3.'
  else
    puts "Running with #{db_adapter} for database adapter"
  end

  ActiveRecord::Base.establish_connection(config[db_adapter])
  ActiveRecord::Migration.suppress_messages do
    load(File.expand_path('schema.rb', File.dirname(__FILE__)))
  end

  ar_classes.each { |klass| klass.reset_column_information }
end

def ar_classes
  ActiveRecord::Base.send(ActiveRecord::Base.respond_to?(:descendants) ? :descendants : :subclasses)
end

def truncate
  ar_classes.each { |klass| klass.delete_all }
end

RSpec.configure do |config|
  config.before(:suite) do
    load_schema
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
    truncate
  end
end
