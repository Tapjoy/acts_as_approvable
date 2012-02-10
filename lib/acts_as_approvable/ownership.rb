module ActsAsApprovable
  module Ownership
    ##
    # Configure approvals to allow ownership by a User model.
    #
    # If a block is given it will be applied to Approval at the class level,
    # allowing you to override functionality on the fly.
    def self.configure(approval = Approval, owner = User, &block)
      approval.send(:include, self)

      ActsAsApprovable.owner_class = owner
      approval.send(:belongs_to, :owner, :class_name => owner.to_s, :foreign_key => :owner_id)

      approval.class_exec(&block) if block
    end

    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)
      base.extend(ClassMethods)
    end

    module InstanceMethods
      ##
      # Set the owner and save the record.
      def assign(owner)
        self.owner = owner
        save
      end

      ##
      # Removed any assigned owner and save the record.
      def unassign
        self.owner = nil
        save
      end
    end

    module ClassMethods
      def owner_class # :nodoc:
        ActsAsApprovable.owner_class
      end

      ##
      # A list of records that can be assigned to an approval. This should be
      # overridden in ActsAsApprovable::Ownership.configure to return only the
      # records you wish to manage approvals.
      def available_owners
        owner_class.all
      end

      ##
      # Build an array from #avaialble_owners usable by #options_for_select.
      # Each element in the array is built with #option_for_owner.
      def options_for_available_owners(with_prompt = false)
        owners = available_owners.map { |owner| option_for_owner(owner) }
        owners.unshift(['(none)', nil]) if with_prompt
        owners
      end

      ##
      # A list of owners that have assigned approvals.
      def assigned_owners
        all(:select => 'DISTINCT(owner_id)', :conditions => 'owner_id IS NOT NULL', :include => :owner).map(&:owner)
      end

      ##
      # Build an array from #assigned_owners usable by #options_for_select.
      # Each element in the array is built with #option_for_owner.
      def options_for_assigned_owners(with_prompt = false)
        owners = assigned_owners.map { |owner| option_for_owner(owner) }
        owners.unshift(['All Users', nil]) if with_prompt
        owners
      end

      private
      def option_for_owner(owner)
        [owner.to_s, owner.id]
      end
    end
  end
end
