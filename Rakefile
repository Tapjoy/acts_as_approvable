require 'rubygems'
require 'bundler/setup'
require 'rspec/core/rake_task'
require 'cucumber'
require 'cucumber/rake/task'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the acts_as_approvable plugin.'
RSpec::Core::RakeTask.new(:test)

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format pretty"
end
