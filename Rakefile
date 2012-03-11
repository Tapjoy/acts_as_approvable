require 'rubygems'
require 'bundler/setup'
require 'rake/testtask'
require 'rspec/core/rake_task'
require 'cucumber'
require 'cucumber/rake/task'
require 'yard'
require 'appraisal'

desc 'Default: run unit tests.'
task :default => :test

desc 'Start a pry session with a database connection open'
task :pry do |t|
  $LOAD_PATH << './lib'
  require 'pry'
  require './spec/spec_helper'

  Support::Database.setup_log(STDOUT)
  Support::Database.load_schema

  #ActsAsApprovable::Ownership.configure
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
RSpec::Core::RakeTask.new(:test)

if RUBY_VERSION =~ /^1\.8/
  begin
    require 'rcov/rcovtask'
    Rcov::RcovTask.new do |t|
      t.libs        << 'test' << 'lib'
      t.rcov_opts   << '--exclude' << '"Library/Ruby/*"' << '--sort' << 'coverage'
      t.pattern     = 'test/*_test.rb'
      t.output_dir  = 'coverage/'
      t.verbose     = true
    end
  rescue LoadError
  end
elsif RUBY_VERSION =~ /^1\.9/
  namespace :test do
    task :coverage do
      ENV['COVERAGE'] = 'true'
      Rake::Task['test'].invoke
    end
  end
end

namespace :test do
  desc 'Setup appraisals and install gems for the gambit run'
  task :setup do
    start = Time.now
    Kernel.system('rbenv each -v bundle install')
    Kernel.system('rbenv each -v bundle exec rake appraisal:install')
    elapsed = Time.now - start

    puts "\nRan everything in #{elapsed} seconds"
  end

  desc 'Run all specs and features across all installed rubies'
  task :gambit do
    start = Time.now
    Kernel.system('rbenv each -v bundle exec rake appraisal test')
    Kernel.system('rbenv each -v bundle exec rake appraisal features')
    elapsed = Time.now - start

    puts "\nRan everything in #{elapsed} seconds"
  end
end

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format pretty"
end

desc 'Generate documentation for the acts_as_approvable plugin.'
YARD::Rake::YardocTask.new do |t|
  yard_dir = (ENV['YARD_DIR'] || 'yardoc')
  t.files   = ['lib/**/*.rb', 'README.md']
  t.options = ['-r', 'README.md', '-o', yard_dir, '--markup', 'markdown']
end
