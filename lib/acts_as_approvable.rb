require 'active_record'

require 'acts_as_approvable/acts_as_approvable'
require 'acts_as_approvable/approval'
require 'acts_as_approvable/error'
require 'acts_as_approvable/ownership'
require 'acts_as_approvable/version'

module ActsAsApprovable
  ##
  # Enable the approval queue at a global level.
  def self.enable
    @enabled = true
  end

  ##
  # Disable the approval queue at a global level.
  def self.disable
    @enabled = false
  end

  ##
  # Returns true if the approval queue is enabled globally.
  def self.enabled?
    @enabled = true if @enabled.nil?
    @enabled
  end

  ##
  # Set the referenced Owner class to be used by generic finders.
  #
  # @see Ownership
  def self.owner_class=(klass)
    @owner_class = klass
  end

  ##
  # Get the referenced Owner class to be used by generic finders.
  #
  # @see Ownership
  def self.owner_class
    @owner_class
  end

  ##
  # Set the engine used for rendering view files.
  def self.view_language=(lang)
    @lang = lang
  end

  ##
  # Get the engine used for rendering view files. Defaults to 'erb'
  def self.view_language
    if Rails.version =~ /^3\./
      Rails.configuration.generators.rails[:template_engine].try(:to_s) || 'erb'
    else
      @lang || 'erb'
    end
  end
end

if Rails.version =~ /^3\./
  module ActsAsApprovable
    class Railtie < Rails::Railtie
      initializer 'acts_as_approvable.configure_rails_initialization' do |app|
        ActiveRecord::Base.send :include, ActsAsApprovable::Model
      end
    end
  end
else
  ActiveRecord::Base.send :include, ActsAsApprovable::Model
end
