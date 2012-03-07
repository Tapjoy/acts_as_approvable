if RUBY_VERSION =~ /^1\.9/
  require 'simplecov'
  SimpleCov.start do
    add_filter '/test/'
  end if ENV['COVERAGE']
end

ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..'))

require 'rubygems'
require 'test/unit'
require 'mocha'
require 'shoulda'
require 'active_record'

require File.dirname(__FILE__) + '/../lib/acts-as-approvable'
require './test/support'

logfile = File.dirname(__FILE__) + '/debug.log'
LOGGER = ActiveRecord::Base.logger = if defined?(ActiveSupport::BufferedLogger)
                                       ActiveSupport::BufferedLogger.new(logfile)
                                     else
                                       Logger.new(logfile)
                                     end

def load_schema
  config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))

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
  end

  ActiveRecord::Base.establish_connection(config[db_adapter])
  ActiveRecord::Migration.suppress_messages do
    load(File.dirname(__FILE__) + '/schema.rb')
  end

  ar_classes.each { |klass| klass.reset_column_information }
end

def ar_classes
  ActiveRecord::Base.send(ActiveRecord::Base.respond_to?(:descendants) ? :descendants : :subclasses)
end

def truncate
  ar_classes.each { |klass| klass.delete_all }
end
