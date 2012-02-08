require 'active_record'

require 'acts_as_approvable/acts_as_approvable'
require 'acts_as_approvable/approval'
require 'acts_as_approvable/error'
require 'acts_as_approvable/ownership'

module ActsAsApprovable
  def self.enable
    @enabled = true
  end

  def self.disable
    @enabled = false
  end

  def self.enabled?
    @enabled ||= true
  end

  def self.owner_class=(klass)
    @owner_class = klass
  end

  def self.owner_class
    @owner_class
  end

  def self.view_language=(lang)
    @lang = lang
  end

  def self.view_language
    @lang || 'erb'
  end
end
