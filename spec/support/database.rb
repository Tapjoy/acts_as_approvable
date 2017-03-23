module Support
  module Database
    def self.setup_log(logfile = nil)
      logfile ||= File.expand_path('../../debug.log', File.dirname(__FILE__))
      ActiveRecord::Base.logger = if defined?(ActiveSupport::BufferedLogger)
                                    ActiveSupport::BufferedLogger.new(logfile)
                                  else
                                    Logger.new(logfile)
                                  end
    end

    def self.load_schema
      require 'sqlite3'

      ActiveRecord::Base.establish_connection({
        adapter: 'sqlite3',
        database: 'spec/acts_as_approvable.db'
      })
      ActiveRecord::Migration.suppress_messages do
        load(File.expand_path('schema.rb', File.dirname(__FILE__)))
      end
    end

    def self.truncate
      [User, Approval, NotApprovable, DefaultApprovable, CreatesApprovable, UpdatesApprovable, DestroysApprovable].each do |klass|
        klass.delete_all
      end
    end
  end
end
