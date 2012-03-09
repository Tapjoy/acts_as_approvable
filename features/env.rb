ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..'))

require 'rubygems'
require 'active_record'

require File.expand_path('../lib/acts-as-approvable', File.dirname(__FILE__))

require File.expand_path('../spec/support/database', File.dirname(__FILE__))
require File.expand_path('../spec/support/models', File.dirname(__FILE__))
