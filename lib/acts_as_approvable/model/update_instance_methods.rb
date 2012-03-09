module ActsAsApprovable
  module Model
    ##
    # Instance methods that apply to the :update event specifically.
    module UpdateInstanceMethods
      ##
      # Retrieve all approval records for `:update` events.
      def update_approvals(all = true)
        all ? approvals.find_all_by_event('update') : approvals.find_all_by_event_and_state('update', 0)
      end

      ##
      # Returns true if the record has any `#update_approvals` that are pending
      # approval.
      def pending_changes?
        !update_approvals(false).empty?
      end

      ##
      # Returns true if any notable (eg. not ignored) fields have been changed.
      def changed_notably?
        notably_changed.any?
      end

      ##
      # Returns an array of any notable (eg. not ignored) fields that have not
      # been changed.
      #
      # @return [Array] a list of changed fields.
      def notably_changed
        approvable_fields.select { |field| changed.include?(field) }
      end

      ##
      # Returns a list of fields that require approval.
      def approvable_fields
        self.class.approvable_fields
      end

      private
      def approvable_update?
        approvals_enabled? and approvable_on?(:update) and changed_notably?
      end

      def approvable_update
        changed = {}
        originals = {}

        notably_changed.each do |attr|
          original, changed_to = changes[attr]

          write_attribute(attr.to_s, original)
          changed[attr] = changed_to
          originals[attr] = original
        end

        @approval = approvals.build(:event => 'update', :state => 'pending', :object => changed, :original => originals)
      end
    end
  end
end
