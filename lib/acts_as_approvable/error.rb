module ActsAsApprovable
  class Error < RuntimeError
    ##
    # Raised when a locked approval is accepted or rejected.
    class Locked < ActsAsApprovable::Error
      def initialize(*args)
        args[0] = 'this approval is locked'
        super(*args)
      end
    end

    ##
    # Raised when a stale approval is accepted.
    class Stale < ActsAsApprovable::Error
      def initialize(*args)
        args[0] = 'this approval is stale and should not be approved'
        super(*args)
      end
    end
  end
end
