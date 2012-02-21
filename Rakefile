require 'rubygems'
require 'bundler/setup'
require 'rake/testtask'
require 'yard'
require 'appraisal'

desc 'Default: run unit tests.'
task :default => :test

desc 'Start a pry session with a database connection open'
task :pry do |t|
  $LOAD_PATH << './lib'
  require 'pry'
  require './test/test_helper'

  ActiveRecord::Base.logger = Logger.new(STDOUT)
  load_schema

  ActsAsApprovable::Ownership.configure
  Pry.start(TOPLEVEL_BINDING)
end

desc 'Copy templates from Rails 3 generators to the Rails 2 generators'
task :copy do |t|
  ['erb', 'haml'].each do |lang|
    Dir["lib/generators/#{lang}/templates/*"].each do |file|
      FileUtils.cp(file, "generators/acts_as_approvable/templates/views/#{lang}/#{File.basename(file)}")
    end
  end
  Dir["lib/generators/acts_as_approvable/templates/*"].each do |file|
    FileUtils.cp(file, "generators/acts_as_approvable/templates/#{File.basename(file)}")
  end
end

desc 'Test the acts_as_approvable plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs    << 'test' << 'lib'
  t.pattern = 'test/*_test.rb'
  t.verbose = true
end

if RUBY_VERSION =~ /^1\.8/
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |t|
    t.libs        << 'test' << 'lib'
    t.rcov_opts   << '--exclude' << '"Library/Ruby/*"' << '--sort' << 'coverage'
    t.pattern     = 'test/*_test.rb'
    t.output_dir  = 'coverage/'
    t.verbose     = true
  end
elsif RUBY_VERSION =~ /^1\.9/
  namespace :test do
    task :coverage do
      ENV['COVERAGE'] = true
      Rake::Task['test'].invoke
    end
  end
end

desc 'Generate documentation for the acts_as_approvable plugin.'
YARD::Rake::YardocTask.new do |t|
  yard_dir = (ENV['YARD_DIR'] || 'yardoc')
  t.files   = ['lib/**/*.rb', 'README.md']
  t.options = ['-r', 'README.md', '-o', yard_dir, '--markup', 'markdown']
end
