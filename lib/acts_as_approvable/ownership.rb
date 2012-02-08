module ActsAsApprovable
  module Ownership
    def self.configure(approval = Approval, owner = User, &block)
      approval.send(:include, self)

      ActsAsApprovable.owner_class = owner
      approval.send(:belongs_to, :owner, :class_name => owner.to_s.tableize.to_sym, :foreign_key => :owner_id)

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
        (@available_owners ||= owner_class.all).dup
      end

      def options_for_available_owners
        (@options_for_available_owners ||= available_owners.map { |owner| option_for_owner(owner) }).dup
      end

      def assigned_owners
        all(:select => 'DISTINCT(owner_id)', :conditions => 'owner_id IS NOT NULL').map(&:owner)
      end

      def options_for_assigned_owners
        assigned_owners.map { |owner| option_for_owner(owner) }
      end

      private
      def option_for_owner(owner)
        [owner.to_s, owner.id]
      end
    end
  end
end
