require 'rake'
require 'rake/testtask'
require 'yard'

desc 'Default: run unit tests.'
task :default => :test

desc 'Start a pry session with a database connection open'
task :pry do |t|
  $LOAD_PATH << './lib'
  require 'pry'
  require 'test/test_helper'

  ActiveRecord::Base.logger = Logger.new(STDOUT)
  load_schema

  ActsAsApprovable::Ownership.configure
  Pry.start(TOPLEVEL_BINDING)
end

desc 'Test the acts_as_approvable plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the acts_as_approvable plugin.'
YARD::Rake::YardocTask.new do |t|
  yard_dir = (ENV['YARD_DIR'] || 'yardoc')
  t.files   = ['lib/**/*.rb', 'README.md']
  t.options = ['-r', 'README.md', '-o', yard_dir]
end
