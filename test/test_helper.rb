ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..'))

require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'active_record'

require File.dirname(__FILE__) + '/../lib/acts_as_approvable'

ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + '/debug.log')

def load_schema
  config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))

  db_adapter = ENV['DB']

  db_adapter ||=
    begin
      require 'sqlite'
      'sqlite'
    rescue MissingSourceFile
      begin
        require 'sqlite3'
        'sqlite3'
      rescue MissingSourceFile
      end
    end

  if db_adapter.nil?
    raise 'No DB Adapter selected. Pass the DB= option to pick one, or install Sqlite or Sqlite3.'
  end

  ActiveRecord::Base.establish_connection(config[db_adapter])
  load(File.dirname(__FILE__) + '/schema.rb')
end
