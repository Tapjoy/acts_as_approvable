module ActsAsApprovable
  ##
  # This module provides the {Approval} class with the ability to assign records
  # as an "owner" of the approval. This is especially useful for tracking purposes
  # when you require it, and can be beneficial when you have an approval queue with
  # a high rate of insertions.
  #
  # By default the ownership functionality will reference a model named `User` and
  # will allow any user to take ownership of an approval.
  module Ownership
    ##
    # Configure approvals to allow ownership by a User model.
    #
    # If a block is given it will be applied to Approval at the class level,
    # allowing you to override functionality on the fly.
    #
    # @param [Hash] options a hash of options for configuration
    # @option options [Object] :model   the model being used for Approval records (defaults to `Approval`).
    # @option options [Object] :owner   the model being used for owner records (defaults to `User`).
    # @option options [Object] :source  class used to override retrieval of owner records.
    def self.configure(options = {}, &block)
      approval = options.delete(:model) { Approval }
      owner = options.delete(:owner) { User }

      approval.send(:include, self)

      ActsAsApprovable.owner_class = owner
      ActsAsApprovable.owner_source = options.delete(:source)

      approval.send(:belongs_to, :owner, :class_name => owner.to_s, :foreign_key => :owner_id)
    end

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.extend(ClassMethods)
    end

    ##
    # Instance methods for approval ownership.
    module InstanceMethods
      ##
      # Set the owner and save the record.
      #
      # @return [Boolean]
      def assign(owner)
        raise ActsAsApprovable::Error::InvalidOwner unless self.class.available_owners.include?(owner)
        self.owner = owner
        save
      end

      ##
      # Removed any assigned owner and save the record.
      #
      # @return [Boolean]
      def unassign
        self.owner = nil
        save
      end
    end

    ##
    # Class methods for approval ownership.
    module ClassMethods
      ##
      # Get the model that represents an owner.
      #
      # @see ActsAsApprovable::Ownership.configure
      def owner_class
        ActsAsApprovable.owner_class
      end

      ##
      # Source class used to override Owner retrieval methods
      #
      # @see ActsAsApprovable::Ownership.configure
      def owner_source
        ActsAsApprovable.owner_source
      end

      ##
      # Attempt to run a method on the configured #owner_source class. If it does
      # not exist yield to the given block.
      def with_owner_source(method, *args)
        if owner_source && owner_source.singleton_class.method_defined?(method)
          owner_source.send(method, *args)
        else
          yield
        end
      end

      ##
      # A list of records that can be assigned to an approval.
      #
      # This method can be overriden by the configured #owner_source.
      def available_owners
        with_owner_source(:available_owners) { owner_class.all }
      end

      ##
      # Build an array from {#available_owners} usable by Rails' `#options_for_select`.
      # Each element in the array is built with {#option_for_owner}.
      #
      # @return [Array]
      def options_for_available_owners(with_prompt = false)
        owners = available_owners.map { |owner| option_for_owner(owner) }
        owners.unshift(['(none)', nil]) if with_prompt
        owners
      end

      ##
      # A list of owners that have assigned approvals.
      #
      # This method can be overriden by the configured #owner_source.
      def assigned_owners
        with_owner_source(:assigned_owners) { all(:select => 'DISTINCT(owner_id)', :conditions => 'owner_id IS NOT NULL', :include => :owner).map(&:owner) }
      end

      ##
      # Build an array from {#assigned_owners} usable by Rails' `#options_for_select`.
      # Each element in the array is built with {#option_for_owner}.
      #
      # @return [Array]
      def options_for_assigned_owners(with_prompt = false)
        owners = assigned_owners.map { |owner| option_for_owner(owner) }
        owners.unshift(['All Users', nil]) if with_prompt
        owners
      end

      ##
      # Helper method that takes an owner record and returns an array for Rails'
      # `#options_for_select`.
      #
      # This method can be overriden by the configured #owner_source.
      #
      # @return [Array] a 2-index array with a display string and value.
      def option_for_owner(owner)
        with_owner_source(:option_for_owner, owner) { [owner.to_str, owner.id] }
      end
    end
  end
end
