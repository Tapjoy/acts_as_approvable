module ActsAsApprovable
  module Model
    ##
    # Instance methods that apply to the `:destroy` event specifically.
    module DestroyInstanceMethods
      ##
      # Retrieve approval records for the destruction event.
      #
      # @param [Boolean] all toggle for returning all or pending approvals
      # @return [Approval]
      def destroy_approvals(all = true)
        all ? approvals.find_all_by_event('destroy') : approvals.find_all_by_event_and_state('destroy', 0)
      end

      ##
      # Returns true if there are any pending `:destroy` event approvals
      def pending_destruction?
        not destroy_approvals(false).empty?
      end

      ##
      # Add a `:destrory` approval event to the queue if approvals are enabled, otherwise
      # destroy the record.
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
