module ActsAsApprovable
  module Model
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      # Declare this in your model to require approval on new records or changes to fields.
      #
      # Options:
      # :on           an array declaring when approval is required (:update or :create)
      # :ignore       an array of fields to ignore
      # :state_field  field to store local state in. by default state is not stored locally.
      #               note that the local state is the state of the creation event, not update
      #               events. Use #pending_changes? to see if there are pending updates for
      #               an object.
      def acts_as_approvable(options = {})
        include InstanceMethods

        cattr_accessor :approvable_on
        self.approvable_on = Array.wrap(options.delete(:on) { [:create, :update] })

        cattr_accessor :approvable_field
        self.approvable_field = options.delete(:state_field)

        cattr_accessor :approvable_ignore
        ignores = Array.wrap(options.delete(:ignore) { [] })
        ignores.push('created_at', 'updated_at', self.approvable_field)
        self.approvable_ignore = ignores.compact.uniq.map(&:to_s)

        cattr_accessor :approvable_only
        self.approvable_only = Array.wrap(options.delete(:only) { [] }).uniq.map(&:to_s)

        cattr_accessor :approvals_active
        self.approvals_active = true

        has_many :approvals, :as => :item, :dependent => :destroy

        if self.approvable_on.include?(:update)
          include UpdateInstanceMethods
          before_update :approvable_update, :if => :approvable_update?
        end

        if self.approvable_on.include?(:create)
          include CreateInstanceMethods
          before_create :approvable_create, :if => :approvable_create?
        end

        after_save :approvable_save, :if => :approvals_enabled?
      end

      def approvals_on
        self.approvals_active = true
      end

      def approvals_off
        self.approvals_active = false
      end
    end

    module CreateInstanceMethods
      def approval
        approvals.find_by_event('create')
      end

      def approval_state
        if self.class.approvable_field
          read_attribute(self.class.approvable_field)
        else
          approval.state
        end
      end

      def set_approval_state(state)
        return unless self.class.approvable_field
        write_attribute(self.class.approvable_field, state)
      end

      def pending?
        approval_state == 'pending' or approval.present? and !approved? and !rejected?
      end

      def approved?
        approval_state == 'approved' or approval.nil? or approval.approved?
      end

      def rejected?
        approval_state == 'rejected' or approval.present? and approval.rejected?
      end

      def approve!
        return unless approvable_on?(:create) && approval.present?
        approval.approve!
      end

      def reject!
        return unless approvable_on?(:create) && approval.present?
        approval.reject!
      end

      private
      def approvable_create?
        approvals_enabled? and approvable_on?(:create)
      end

      def approvable_create
        @approval = approvals.build(:event => 'create', :state => 'pending')
        set_approval_state('pending')
      end
    end

    module UpdateInstanceMethods
      def update_approvals
        approvals.find_all_by_event('update')
      end

      def pending_changes?
        !update_approvals.empty?
      end

      def changed_notably?
        notably_changed.any?
      end

      def notably_changed
        unless self.class.approvable_only.empty?
          self.class.approvable_only.select { |field| changed.include?(field) }
        else
          changed - self.class.approvable_ignore
        end
      end

      private
      def approvable_update?
        approvals_enabled? and approvable_on?(:update) and changed_notably?
      end

      def approvable_update
        changed = {}
        notably_changed.each do |attr|
          original, changed_to = changes[attr]

          write_attribute(attr.to_s, original)
          changed[attr] = changed_to
        end

        @approval = approvals.build(:event => 'update', :state => 'pending', :object => changed)
      end
    end

    module InstanceMethods
      def approvals_enabled?
        ActsAsApprovable.enabled? and self.class.approvals_active
      end

      def approvals_disabled?
        !approvals_active?
      end

      def approvable_on?(event)
        self.class.approvable_on.include?(event)
      end

      def before_approve(approval); end
      def after_approve(approval); end
      def before_reject(approval); end
      def after_reject(approval); end

      # Executes a block with the approval queue off
      def without_approval(&block)
        memory = self.class.approvals_active # If we use #approvals_enabled? the global state might be incorrectly applied.
        self.class.approvals_off
        instance_eval &block
      ensure
        self.class.approvals_on if memory
      end

      private
      def approvable_save
        @approval.save if @approval.present? && @approval.new_record?
      end
    end
  end
end

ActiveRecord::Base.send :include, ActsAsApprovable::Model
