require 'rake'
require 'rake/testtask'
require 'rcov/rcovtask'
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
  t.libs    << 'test' << 'lib'
  t.pattern = 'test/*_test.rb'
  t.verbose = true
end

Rcov::RcovTask.new do |t|
  t.libs        << 'test' << 'lib'
  t.rcov_opts   << '--exclude' << '"Library/Ruby/*"' << '--sort' << 'coverage'
  t.pattern     = 'test/*_test.rb'
  t.output_dir  = 'coverage/'
  t.verbose     = true
end

desc 'Generate documentation for the acts_as_approvable plugin.'
YARD::Rake::YardocTask.new do |t|
  yard_dir = (ENV['YARD_DIR'] || 'yardoc')
  t.files   = ['lib/**/*.rb', 'README.md']
  t.options = ['-r', 'README.md', '-o', yard_dir, '--markup', 'markdown']
end

desc 'Generate documentation and update the gh-pages branch'
task :site => :yard do |t|
  def run_or_quit(cmd)
    puts "Running #{cmd}"
    `#{cmd}`
    raise "Command failed!" if $? != 0
  end

  run_or_quit('git checkout gh-pages')
  run_or_quit('rsync -rv --delete --exclude yardoc/ --exclude .git/ --exclude .gitignore yardoc/ ./')
  run_or_quit('git add .')
  run_or_quit('git commit -m "Updating documentation"')
  run_or_quit('git push origin gh-pages')
  run_or_quit('git checkout master')
end
