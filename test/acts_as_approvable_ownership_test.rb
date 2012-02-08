require 'test_helper'

class ActsAsApprovableOwnershipTest < Test::Unit::TestCase
  load_schema

  context 'with default configuration' do
    setup { ActsAsApprovable::Ownership.configure }

    should 'respond to .owner_class' do
      assert_respond_to Approval, :owner_class
    end

    should 'respond to .available_owners' do
      assert_respond_to Approval, :available_owners
    end

    should 'respond to .options_for_available_owners' do
      assert_respond_to Approval, :options_for_available_owners
    end

    should 'respond to .assigned_owners' do
      assert_respond_to Approval, :assigned_owners
    end

    should 'respond to .options_for_assigned_owners' do
      assert_respond_to Approval, :options_for_assigned_owners
    end
  end

  context 'given a block' do
    setup do
      ActsAsApprovable::Ownership.configure do
        def self.available_owners
          [1, 2, 3]
        end
      end
    end

    should 'allow overriding methods' do
      assert_equal [1, 2, 3], Approval.available_owners
    end
  end
end
