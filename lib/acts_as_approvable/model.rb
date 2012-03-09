require 'acts_as_approvable/model/class_methods'
require 'acts_as_approvable/model/instance_methods'
require 'acts_as_approvable/model/create_instance_methods'
require 'acts_as_approvable/model/update_instance_methods'

module ActsAsApprovable
  ##
  # The meat of {ActsAsApprovable}. This applies methods for the configured approval events
  # and configures the required relationships.
  module Model
    # Declare this in your model to require approval on new records or changes to fields.
    #
    # @param [Hash] options the options for this models approval workflow.
    # @option options [Symbol,Array] :on    The events to require approval on (`:create` or `:update`).
    # @option options [String] :state_field The local field to store `:create` approval state.
    # @option options [Array]  :ignore      A list of fields to ignore. By default we ignore `:created_at`, `:updated_at` and
    #                                       the field specified in `:state_field`.
    # @option options [Array]  :only        A list of fields to explicitly require approval on. This list supercedes `:ignore`.
    def acts_as_approvable(options = {})
      extend ClassMethods
      include InstanceMethods

      cattr_accessor :approvable_on
      self.approvable_on = Array.wrap(options.delete(:on) { [:create, :update] })

      cattr_accessor :approvable_field
      self.approvable_field = options.delete(:state_field)

      cattr_accessor :approvable_ignore
      ignores = Array.wrap(options.delete(:ignore) { [] })
      ignores.push('created_at', 'updated_at', primary_key, self.approvable_field)
      self.approvable_ignore = ignores.compact.uniq.map(&:to_s)

      cattr_accessor :approvable_only
      self.approvable_only = Array.wrap(options.delete(:only) { [] }).uniq.map(&:to_s)

      cattr_accessor :approvals_disabled
      self.approvals_disabled = false

      has_many :approvals, :as => :item, :dependent => :destroy

      if approvable_on?(:update)
        include UpdateInstanceMethods
        before_update :approvable_update, :if => :approvable_update?
      end

      if approvable_on?(:create)
        include CreateInstanceMethods
        before_create :approvable_create, :if => :approvable_create?
      end

      after_save :approvable_save, :if => :approvals_enabled?
    end
  end
end
