require 'rake'
require 'rake/testtask'
require 'rdoc/task'

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
RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'ActsAsApprovable'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
