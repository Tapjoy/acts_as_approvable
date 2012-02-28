module ActsAsApprovable
  module Generators
    module Base
      protected
      def owner?
        options[:owner].present?
      end

      def owner
        options[:owner] == 'owner' ? 'User' : options[:owner]
      end

      def scripts?
        options[:scripts]
      end

      def collection_actions
        actions = [:index, :history]
        actions << :mine if owner?
        actions.map { |a| ":#{a}" }
      end

      def member_actions
        actions = [:approve, :reject]
        actions << :assign if owner?
        actions.map { |a| ":#{a}" }
      end
    end
  end
end
