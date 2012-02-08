module ActsAsApprovable
  class Error < RuntimeError
    class Locked < ActsAsApprovable::Error
      def initialize(*args)
        args[0] = 'this approval is locked'
        super(*args)
      end
    end

    class Stale < ActsAsApprovable::Error
      def initialize(*args)
        args[0] = 'this approval is stale and should not be approved'
        super(*args)
      end
    end
  end
end
