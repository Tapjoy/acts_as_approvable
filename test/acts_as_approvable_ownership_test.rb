require 'test_helper'

class ActsAsApprovableOwnershipTest < Test::Unit::TestCase
  load_schema

  def teardown
    ActiveRecord::Base.send(:subclasses).each do |klass|
      klass.delete_all
    end
  end

  context 'with default configuration' do
    setup do
      # Reset from test below
      ActsAsApprovable::Ownership.configure do
        def self.available_owners
          owner_class.all
        end
      end
    end

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

    context 'and some objects' do
      setup do
        @employee = Employee.create
        @approval = @employee.approval

        @user1, @user2 = User.without_approval { [create, create] }
      end

      context '#assign' do
        should 'raise an error when the record is not assignable' do
          assert_raise(ActsAsApprovable::Error::InvalidOwner) { @approval.assign(@employee) }
        end

        should 'allow assignment of a valid record' do
          assert_nothing_raised { @approval.assign(@user1) }
          assert_equal @approval.owner, @user1
        end
      end

      context '#unassign' do
        setup do
          @approval.owner = @user1
          @approval.unassign
        end

        should 'nullify the owner' do
          assert @approval.owner.nil?
        end
      end

      context '.available_owners' do
        should 'contain all available owners' do
          assert_equal [@user1, @user2], Approval.available_owners
        end
      end

      context '.options_for_available_owners' do
        should 'format all available owners for a #options_for_select' do
          assert_equal Approval.options_for_available_owners, [
            [@user1.to_str, @user1.id],
            [@user2.to_str, @user2.id]
          ]
        end

        should 'insert a prompt if requested' do
          assert_equal ['(none)', nil], Approval.options_for_available_owners(true).first
        end
      end

      context 'with some assigned owners' do
        setup do
          @user3 = User.without_approval { create }

          @approval.assign(@user1)
          Employee.create.approval.assign(@user3)
        end

        context '.assigned_owners' do
          should 'contain all assigned owners' do
            assert_equal [@user1, @user3], Approval.assigned_owners
          end
        end

        context '.options_for_assigned_owners' do
          should 'format all assigned owners for #options_for_select' do
            assert_equal Approval.options_for_assigned_owners, [
              [@user1.to_str, @user1.id],
              [@user3.to_str, @user3.id]
            ]
          end

          should 'insert a prompt if requested' do
            assert_equal ['All Users', nil], Approval.options_for_assigned_owners(true).first
          end
        end
      end
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
