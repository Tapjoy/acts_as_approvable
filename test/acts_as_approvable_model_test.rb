require 'test_helper'

class User < ActiveRecord::Base
  acts_as_approvable :on => :create, :state_field => :state
end

class Project < ActiveRecord::Base
  acts_as_approvable :ignore => :title, :on => :update
end

class Employee < ActiveRecord::Base
  acts_as_approvable
end

class ActsAsApprovableModelTest < Test::Unit::TestCase
  load_schema

  context 'A record with update only approval' do
    setup { @project = Project.create }

    should 'have no approvals' do
      assert @project.approvals.empty?
    end

    context 'which updates an ignored column' do
      setup { @project.update_attribute(:title, 'Ignore Me') }

      should 'not have an approval' do
        assert @project.approvals.empty?
      end
    end

    context 'which updates an ignore column and a non-ignored column' do
      setup { @project.update_attributes(:title => 'Ignore Me', :description => 'Must Review') }

      should 'have one approval' do
        assert_equal 1, @project.approvals.size
      end

      should 'not update the records non-ignored column' do
        assert_equal nil, @project.description
      end

      should 'have the description on the approval' do
        assert @project.approvals.last.object.key?('description')
        assert_equal 'Must Review', @project.approvals.last.object['description']
      end
    end

    context 'that is altered using #without_approvable' do
      setup { @project.without_approval { update_attribute(:description, 'updated') } }

      should 'not have an approval object' do
        assert @project.approvals.empty?
      end
    end
  end

  context 'An approval record' do
    setup do
      @project = Project.create
      @project.update_attribute(:description, 'review')
      @approval = @project.approvals.last
    end

    should 'not be locked by default' do
      assert @approval.unlocked?
      assert !@approval.locked?
    end

    should 'be pending' do
      assert @approval.pending?
      assert !@approval.approved?
      assert !@approval.rejected?
    end

    context 'that is accepted' do
      setup { @approval.approve! }

      should 'be locked' do
        assert @approval.locked?
        assert !@approval.unlocked?
      end

      should 'be approved' do
        assert @approval.approved?
        assert !@approval.rejected?
        assert !@approval.pending?
      end

      should 'update the target item' do
        assert_equal @approval.object[:description], @approval.item.description
      end

      should 'raise an error if approved again' do
        assert_raise(RuntimeError) { @approval.approve! }
      end

      should 'raise an error if rejected' do
        assert_raise(RuntimeError) { @approval.reject! }
      end
    end

    context 'that is rejected' do
      setup { @approval.reject! }

      should 'be locked' do
        assert @approval.locked?
        assert !@approval.unlocked?
      end

      should 'be rejected' do
        assert @approval.rejected?
        assert !@approval.approved?
        assert !@approval.pending?
      end

      should 'not update the target item' do
        assert_equal nil, @approval.item.description
      end

      should 'raise an error if approved' do
        assert_raise(RuntimeError) { @approval.approve! }
      end

      should 'raise an error if rejected again' do
        assert_raise(RuntimeError) { @approval.reject! }
      end
    end
  end

  context 'A record with create only approval' do
    setup { @user = User.create }

    should 'be pending by default' do
      assert @user.pending?
      assert !@user.approved?
      assert !@user.rejected?
    end

    should 'have an approval object' do
      assert_equal 1, @user.approvals.size
    end

    should 'set the local state' do
      assert_equal 'pending', @user.state
    end

    context 'when approved' do
      setup { @user.approve! }

      should 'be approved' do
        assert @user.approved?
        assert !@user.rejected?
        assert !@user.pending?
      end

      should 'update the local state' do
        assert_equal 'approved', @user.state
      end
    end

    context 'when rejected' do
      setup { @user.reject! }

      should 'be rejected' do
        assert @user.rejected?
        assert !@user.approved?
        assert !@user.pending?
      end

      should 'update the local state' do
        assert_equal 'rejected', @user.state
      end
    end
  end

  context 'A record with default settings' do
    setup { @employee = Employee.create }

    should 'be pending by default' do
      assert @employee.pending?
      assert !@employee.approved?
      assert !@employee.rejected?
    end

    should 'get the state from the approval record' do
      assert_equal @employee.approval_state, @employee.approval.state
    end

    context 'when updated' do
      setup { @employee.update_attributes(:name => 'John Doe') }

      should 'not update the attribute' do
        assert_equal nil, @employee.name
      end

      should 'create an approval record' do
        assert_equal 1, @employee.update_approvals.size
      end
    end
  end
end
