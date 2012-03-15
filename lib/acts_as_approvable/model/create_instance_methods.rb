module ActsAsApprovable
  module Model
    ##
    # Instance methods that apply to the `:create` event specifically.
    module CreateInstanceMethods
      ##
      # Retrieve approval record for the creation event.
      #
      # @return [Approval]
      def approval
        approvals.find_by_event('create')
      end

      ##
      # Get the approval state of the current record from either the local state
      # field or, if no state field exists, the creation approval object.
      #
      # @return [String] one of `'pending'`, `'approved`' or `'rejected'`.
      def approval_state
        if self.class.approvable_field
          send(self.class.approvable_field)
        elsif approval.present?
          approval.state
        end
      end

      ##
      # Set the records local approval state.
      #
      # @param [String] state one of `'pending'`, `'approved`' or `'rejected'`.
      def set_approval_state(state)
        return unless self.class.approvable_field
        send("#{self.class.approvable_field}=".to_sym, state)
      end

      ##
      # Returns true if the record is pending approval.
      def pending?
        approval_state.present? ? approval_state == 'pending' : approval.try(:pending?)
      end

      ##
      # Returns true if the record has been approved.
      def approved?
        approval_state.present? ? approval_state == 'approved' : approval.try(:approved?)
      end

      ##
      # Returns true if the record has been rejected.
      def rejected?
        approval_state.present? ? approval_state == 'rejected' : approval.try(:rejected?)
      end

      ##
      # Approves the record through {Approval#approve!}
      #
      # @return [Boolean]
      def approve!
        return unless approvable_on?(:create) && approval.present?
        approval.approve!
      end

      ##
      # Rejects the record through {Approval#reject!}
      #
      # @return [Boolean]
      def reject!
        return unless approvable_on?(:create) && approval.present?
        approval.reject!
      end

      def reset!
        return unless approvable_on?(:create) && approval.present?
        approval.reset!
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
  end
end
