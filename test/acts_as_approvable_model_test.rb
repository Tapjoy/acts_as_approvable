require 'test_helper'

class ActsAsApprovableModelTest < Test::Unit::TestCase
  load_schema

  def teardown
    ActiveRecord::Base.send(:subclasses).each do |klass|
      klass.delete_all
    end
  end

  context 'A record with update only approval' do
    context 'and ignored fields' do
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

        should 'not update the records ignored column' do
          assert_equal nil, @project.description
        end

        should 'update the records non-ignored columns' do
          assert_equal 'Ignore Me', @project.title
        end

        should 'have the description on the approval' do
          assert @project.approvals.last.object.key?('description')
          assert_equal 'Must Review', @project.approvals.last.object['description']
        end
      end

      context 'that is altered using #without_approval' do
        should 'not have an approval object' do
          @project.without_approval { update_attribute(:description, 'updated') }
          assert @project.approvals.empty?
        end

        should 'correctly restore approval queue state' do
          assert @project.approvals_on?
          @project.approvals_off
          assert !@project.approvals_on?
          @project.without_approval { update_attribute(:description, 'updated') }
          assert !@project.approvals_on?
        end
      end
    end

    context 'and "only" fields' do
      setup { @game = Game.create }

      should 'have no approvals' do
        assert @game.approvals.empty?
      end

      context 'which updates an only column' do
        setup { @game.update_attribute(:title, 'review') }

        should 'have an approval' do
          assert_equal 1, @game.approvals.size
        end

        should 'have pending changes' do
          assert @game.pending_changes?
        end
      end

      context 'which updates an only column and another column' do
        setup { @game.update_attributes(:title => 'review', :description => 'no review') }

        should 'have one approval' do
          assert_equal 1, @game.approvals.size
        end

        should 'not update the records only column' do
          assert_equal nil, @game.title
        end

        should 'update the records other fields' do
          assert_equal 'no review', @game.description
        end

        should 'have the title on the approval' do
          assert @game.approvals.last.object.key?('title')
          assert_equal 'review', @game.approvals.last.object['title']
        end
      end

      context 'that is altered using #without_approval' do
        setup { @game.without_approval { update_attribute(:title, 'updated') } }

        should 'not have an approval object' do
          assert @game.approvals.empty?
        end
      end

      context 'with approval queue disabled' do
        context 'at the record level' do
          setup do
            @game.approvals_off
            @game.update_attributes(:title => 'review')
          end

          teardown { @game.approvals_on }

          should 'have approvals off' do
            assert @game.approvals_disabled?
          end

          should 'not have an approval object' do
            assert @game.approvals.empty?
          end
        end

        context 'at the model level' do
          setup do
            Game.approvals_off
            @game.update_attributes(:title => 'review')
          end

          teardown { Game.approvals_on }

          should 'have approvals off' do
            assert @game.approvals_disabled?
          end

          should 'not have an approval object' do
            assert @game.approvals.empty?
          end
        end

        context 'at the global level' do
          setup do
            ActsAsApprovable.disable
            @game.update_attributes(:title => 'review')
          end

          teardown { ActsAsApprovable.enable }

          should 'have approvals off' do
            assert @game.approvals_disabled?
          end

          should 'not have an approval object' do
            assert @game.approvals.empty?
          end
        end
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

    should 'check attributes in object' do
      @approval.object['foo'] = 'bar'
      @approval.approve!
      assert_equal @approval.object['description'], @approval.item.description
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
        assert_equal @approval.object['description'], @approval.item.description
      end

      should 'raise an error if approved again' do
        assert_raise(ActsAsApprovable::Error::Locked) { @approval.approve! }
      end

      should 'raise an error if rejected' do
        assert_raise(ActsAsApprovable::Error::Locked) { @approval.reject! }
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
        assert_raise(ActsAsApprovable::Error::Locked) { @approval.approve! }
      end

      should 'raise an error if rejected again' do
        assert_raise(ActsAsApprovable::Error::Locked) { @approval.reject! }
      end
    end

    context 'that is stale' do
      setup { @approval.update_attributes(:created_at => 10.days.ago) }

      should 'be stale' do
        assert @approval.stale?
        assert !@approval.fresh?
      end

      should 'raise an error if approved' do
        assert_raise(ActsAsApprovable::Error::Stale) { @approval.approve! }
        assert @approval.pending?
      end

      should 'not raise an error if rejected' do
        assert_nothing_raised { @approval.reject! }
        assert @approval.rejected?
      end

      should 'allow approval when forced' do
        assert_nothing_raised { @approval.approve!(true) }
        assert @approval.approved?
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
      setup { @user.approve!; @user.reload }

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
      setup { @user.reject!; @user.reload }

      should 'be rejected' do
        assert @user.rejected?
        assert !@user.approved?
        assert !@user.pending?
      end

      should 'update the local state' do
        assert_equal 'rejected', @user.state
      end
    end

    context '.without_approval' do
      should 'disable approvals for the given block' do
        @user = User.without_approval { create }
        assert @user.approval.nil?
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

    context 'when approving' do
      setup { @approval = @employee.approval }

      should 'call before_approve hook' do
        @approval.item.expects(:before_approve).once
        @approval.approve!
      end

      should 'call after_approve hook' do
        @approval.item.expects(:after_approve).once
        @approval.approve!
      end

      should 'halt if before_approve returns false' do
        @approval.item.stubs(:before_approve).returns(false)
        @approval.approve!
        assert @approval.item.pending?
      end
    end

    context 'when rejecting' do
      setup { @approval = @employee.approval }

      should 'call before_reject hook' do
        @approval.item.expects(:before_reject).once
        @approval.reject!
      end

      should 'call after_reject hook' do
        @approval.item.expects(:after_reject).once
        @approval.reject!
      end

      should 'halt if before_reject returns false' do
        @approval.item.stubs(:before_reject).returns(false)
        @approval.reject!
        assert @approval.item.pending?
      end
    end
  end

  context '.options_for_state' do
    should 'return an array' do
      assert_kind_of Array, Approval.options_for_state
    end

    should 'contain our states' do
      assert Approval.options_for_state.include?(['All', 'all'])
      assert Approval.options_for_state.include?(['Pending', 'pending'])
      assert Approval.options_for_state.include?(['Approved', 'approved'])
      assert Approval.options_for_state.include?(['Rejected', 'rejected'])
    end
  end

  context '.options_for_type' do
    context 'without approval records' do
      should 'be empty' do
        assert Approval.options_for_type.empty?
      end
    end

    context 'with approval records' do
      setup do
        Project.create.update_attributes(:description => 'review')
        Game.create.update_attributes(:title => 'review')
        User.create
      end

      should 'contain all types with approvals' do
        assert Approval.options_for_type.include?('Project')
        assert Approval.options_for_type.include?('Game')
        assert Approval.options_for_type.include?('User')
      end
    end
  end
end
