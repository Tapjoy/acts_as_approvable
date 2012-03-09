module ActsAsApprovable
  module Model
    ##
    # Instance methods that apply to both `:update` and `:create` events.
    module InstanceMethods
      ##
      # Returns true if the approval queue is active at both the local and global
      # level. Note that the global level supercedes the local level.
      def approvals_enabled?
        global_approvals_on? and model_approvals_on? and approvals_on?
      end

      ##
      # Returns the inverse of `#approvals_enabled?`
      def approvals_disabled?
        not approvals_enabled?
      end

      def approvals_off
        @approvals_disabled = true
      end

      def approvals_on
        @approvals_disabled = false
      end

      def approvals_on?
        not @approvals_disabled
      end

      def model_approvals_on?
        self.class.approvals_on?
      end

      def global_approvals_on?
        ActsAsApprovable.enabled?
      end

      ##
      # Returns true if the model is configured to use the approval queue on the
      # given event (`:create` or `:update`).
      def approvable_on?(event)
        self.class.approvable_on?(event)
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
        enable = approvals_on? # If we use #approvals_enabled? the global state might be incorrectly applied.
        approvals_off
        yield(self)
      ensure
        approvals_on if enable
      end

      def save_without_approval(*args)
        without_approval { |i| save(*args) }
      end

      def save_without_approval!(*args)
        without_approval { |i| save!(*args) }
      end

      private
      def approvable_save
        @approval.save if @approval.present? && @approval.new_record?
      end
    end
  end
end
