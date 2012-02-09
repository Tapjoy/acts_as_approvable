module ActsAsApprovable
  module Ownership
    def self.configure(approval = Approval, owner = User, &block)
      approval.send(:include, self)

      ActsAsApprovable.owner_class = owner
      approval.send(:belongs_to, :owner, :class_name => owner.to_s, :foreign_key => :owner_id)

      approval.class_exec(&block) if block
    end

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.extend(ClassMethods)
    end

    module InstanceMethods
      def assign(owner)
        self.owner = owner
        save
      end

      def unassign
        self.owner = nil
        save
      end
    end

    module ClassMethods
      def owner_class
        ActsAsApprovable.owner_class
      end

      def available_owners
        owner_class.all
      end

      def options_for_available_owners(with_prompt = false)
        owners = available_owners.map { |owner| option_for_owner(owner) }
        owners.unshift(['(none)', nil]) if with_prompt
        owners
      end

      def assigned_owners
        all(:select => 'DISTINCT(owner_id)', :conditions => 'owner_id IS NOT NULL', :include => :owner).map(&:owner)
      end

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
