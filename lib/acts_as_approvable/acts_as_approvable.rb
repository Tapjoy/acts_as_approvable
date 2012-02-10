module ActsAsApprovable
  module Model
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      # Declare this in your model to require approval on new records or changes to fields.
      #
      # Options:
      # 
      # * <tt>:on</tt> - an array declaring when approval is required (<tt>:update</tt> or <tt>:create</tt>)
      # * <tt>:ignore</tt> - an array of fields to ignore
      # * <tt>:only</tt> - an array of fields that are explicitly approvable. This option supercedes <tt>:ignore</tt>.
      # * <tt>:state_field</tt> - field to store local state in. by default state is not stored locally. Note that the local state is the state of the creation event, not update events. Use #pending_changes? to see if there are pending updates for an object.
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

      ##
      # Enable the approval queue for this model.
      def approvals_on
        self.approvals_active = true
      end

      ##
      # Disable the approval queue for this model.
      def approvals_off
        self.approvals_active = false
      end
    end

    ##
    # Instance methods that apply to the :create event specifically.
    module CreateInstanceMethods
      ##
      # Retrieve approval record for the creation event.
      def approval
        approvals.find_by_event('create')
      end

      ##
      # Get the approval state of the current record from either the
      # local state field or, if no state field exists, the creation
      # approval object.
      def approval_state
        if self.class.approvable_field
          read_attribute(self.class.approvable_field)
        else
          approval.state
        end
      end

      ##
      # Set the records local approval state.
      def set_approval_state(state)
        return unless self.class.approvable_field
        write_attribute(self.class.approvable_field, state)
      end

      ##
      # Returns true if the record is pending approval.
      def pending?
        approval_state == 'pending' or approval.present? and !approved? and !rejected?
      end

      ##
      # Returns true if the record has been approved.
      def approved?
        approval_state == 'approved' or approval.nil? or approval.approved?
      end

      ##
      # Returns true if the record has been rejected.
      def rejected?
        approval_state == 'rejected' or approval.present? and approval.rejected?
      end

      ##
      # Approves the record through Approval#approve!
      def approve!
        return unless approvable_on?(:create) && approval.present?
        approval.approve!
      end

      ##
      # Rejects the record through Approval#reject!
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

    ##
    # Instance methods that apply to the :update event specifically.
    module UpdateInstanceMethods
      ##
      # Retrieve all approval records for update events.
      def update_approvals
        approvals.find_all_by_event('update')
      end

      ##
      # Returns true if the record has any #update_approvals that are pending
      # approval.
      def pending_changes?
        !update_approvals.empty?
      end

      ##
      # Returns true if any notable (eg. not ignored) fields have been changed.
      def changed_notably?
        notably_changed.any?
      end

      ##
      # Returns an array of any notable (eg. not ignored) fields that have not
      # been changed.
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

    ##
    # Instance methods that apply to both :update and :create events.
    module InstanceMethods
      ##
      # Returns true if the approval queue is active at both the local and global
      # level. Note that the global level supercedes the local level.
      def approvals_enabled?
        ActsAsApprovable.enabled? and self.class.approvals_active
      end

      ##
      # Returns the inverse of #approvals_enabled?
      def approvals_disabled?
        !approvals_active?
      end

      ##
      # Returns true if the model is configured to use the approval queue on the
      # given event (:create or :update).
      def approvable_on?(event)
        self.class.approvable_on.include?(event)
      end

      ##
      # A filter that is run before the record can be approved. Returning false
      # stops the approval process from completing.
      def before_approve(approval); end

      ##
      # A filter that is run after the record has been approved.
      def after_approve(approval); end

      ##
      # A filter that is run before the record can be rejected. Returning false
      # stops the rejection process from completing.
      def before_reject(approval); end

      ##
      # A filter that is run after the record has been rejected.
      def after_reject(approval); end

      ##
      # Execute a code block while the approval queue is temporarily disabled. The
      # queue state will be returned to it's previous value, either on or off.
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
