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
        puts
        puts
        puts "You must run tests using one of the available appraisals. `bundle exec rake -T` to list, `bundle exec rake appraisal:rails31` to run against Rails 3.1 and SQLite."
        exit
      end

      ActiveRecord::Base.establish_connection(config[db_adapter])
      ActiveRecord::Migration.suppress_messages do
        load(File.expand_path('schema.rb', File.dirname(__FILE__)))
      end

      [User, Approval, NotApprovable, DefaultApprovable, CreatesApprovable, CreatesWithStateApprovable, UpdatesApprovable, UpdatesIgnoreFieldsApprovable, UpdatesOnlyFieldsApprovable].each do |klass|
        klass.reset_column_information
      end
    end

    def self.truncate
      [User, Approval, NotApprovable, DefaultApprovable, CreatesApprovable, UpdatesApprovable].each do |klass|
        klass.delete_all
      end
    end
  end
end
