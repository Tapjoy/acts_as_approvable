module ActsAsApprovable
  module Model
    ##
    # Instance methods that apply to the `:destroy` event specifically.
    module DestroyInstanceMethods
      ##
      # Retrieve approval record for the destruction event.
      #
      # @return [Approval]
      def destroy_approvals(all = true)
        all ? approvals.find_all_by_event('destroy') : approvals.find_all_by_event_and_state('destroy', 0)
      end

      def pending_destruction?
        not destroy_approvals(false).empty?
      end

      def destroy
        approvable_destroy? ? request_destruction : super
      end

      private
      def approvable_destroy?
        approvals_enabled? and approvable_on?(:destroy)
      end

      def request_destruction
        approvals.create!(:event => 'destroy', :state => 'pending', :original => attributes)
      end
    end
  end
end
