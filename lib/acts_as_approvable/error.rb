module ActsAsApprovable
  class Error < RuntimeError
    ##
    # Raised when a locked approval is accepted or rejected.
    class Locked < ActsAsApprovable::Error
      def initialize(*args)
        super('this approval is locked')
      end
    end

    ##
    # Raised when a stale approval is accepted.
    class Stale < ActsAsApprovable::Error
      def initialize(*args)
        super('this approval is stale and should not be approved')
      end
    end

    ##
    # Raised when a record is assigned as owner that is not found in
    # {ActsAsApprovable::Ownership::ClassMethods#available_owners}.
    class InvalidOwner < ActsAsApprovable::Error
      def initialize(*args)
        super('this record cannot be assigned as an owner')
      end
    end

    class InvalidTransition < ActsAsApprovable::Error
      def initialize(from, to, approval)
        super("you may not transition from #{from} to #{to} in a #{approval.event} approval")
      end
    end
  end
end
