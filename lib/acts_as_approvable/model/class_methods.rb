module ActsAsApprovable
  module Model
    ##
    # Class methods available after acts_as_approvable has been called
    module ClassMethods
      ##
      # Returns true if the approval queue is active at both the local and global
      # level. Note that the global level supercedes the local level.
      def approvals_enabled?
        global_approvals_on? and approvals_on?
      end

      def approvals_disabled?
        not approvals_enabled?
      end

      ##
      # Enable the approval queue for this model.
      def approvals_on
        self.approvals_disabled = false
      end

      ##
      # Disable the approval queue for this model.
      def approvals_off
        self.approvals_disabled = true
      end

      def approvals_on?
        not self.approvals_disabled
      end

      def global_approvals_on?
        ActsAsApprovable.enabled?
      end

      ##
      # Returns true if the model is configured to use the approval queue on the
      # given event (`:create` or `:update`).
      def approvable_on?(event)
        self.approvable_on.include?(event)
      end

      ##
      # Returns a list of fields that require approval.
      def approvable_fields
        return self.approvable_only unless self.approvable_only.empty?
        column_names - self.approvable_ignore
      end

      ##
      # Execute a code block while the approval queue is temporarily disabled. The
      # queue state will be returned to it's previous value, either on or off.
      def without_approval(&block)
        enable = self.approvals_on?
        approvals_off
        yield(self)
      ensure
        approvals_on if enable
      end
    end
  end
end
