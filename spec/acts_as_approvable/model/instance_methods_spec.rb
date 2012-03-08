require 'spec_helper'

describe ActsAsApprovable::Model::InstanceMethods do
  subject { DefaultApprovable.new }

  describe '#approvals_enabled?' do
    before(:each) do
      subject.stub(:global_approvals_on? => true)
      subject.stub(:model_approvals_on? => true)
      subject.stub(:approvals_on? => true)
    end

    context 'when approvals are globally disabled' do
      before(:each) do
        subject.stub(:global_approvals_on? => false)
      end

      it 'returns false' do
        subject.approvals_enabled?.should be_false
      end

      it 'checks the global status' do
        subject.should_receive(:global_approvals_on?).and_return(false)
        subject.approvals_enabled?
      end

      it 'does not check the model status' do
        subject.should_not_receive(:model_approvals_on?)
        subject.approvals_enabled?
      end

      it 'does not check the record status' do
        subject.should_not_receive(:approvals_on?)
        subject.approvals_enabled?
      end
    end

    context 'when approvals are disabled for the Model' do
      before(:each) do
        subject.stub(:model_approvals_on? => false)
      end

      it 'returns false' do
        subject.approvals_enabled?.should be_false
      end

      it 'checks the global status' do
        subject.should_receive(:global_approvals_on?).and_return(true)
        subject.approvals_enabled?
      end

      it 'checks the model status' do
        subject.should_receive(:model_approvals_on?).and_return(false)
        subject.approvals_enabled?
      end

      it 'does not check the record status' do
        subject.should_not_receive(:approvals_on?)
        subject.approvals_enabled?
      end
    end

    context 'when approvals are disabled for the Record' do
      before(:each) do
        subject.stub(:approvals_on? => false)
      end

      it 'returns false' do
        subject.approvals_enabled?.should be_false
      end

      it 'checks the global status' do
        subject.should_receive(:global_approvals_on?).and_return(true)
        subject.approvals_enabled?
      end

      it 'checks the model status' do
        subject.should_receive(:model_approvals_on?).and_return(true)
        subject.approvals_enabled?
      end

      it 'checks the record status' do
        subject.should_receive(:approvals_on?).and_return(false)
        subject.approvals_enabled?
      end
    end
  end

  describe '#approvals_disabled?' do
    before(:each) do
      subject.stub(:approvals_enabled? => true)
    end

    it 'returns the inverse of the approval queue status' do
      subject.approvals_disabled?.should == !subject.approvals_enabled?
    end

    it 'calls #approvals_enabled? for the status' do
      subject.should_receive(:approvals_enabled?).and_return(true)
      subject.approvals_disabled?
    end
  end

  describe '#approvals_off' do
    before(:each) do
      subject.approvals_off
    end

    it 'disables the record level approval queue' do
      subject.approvals_on?.should be_false
    end
  end

  describe '#approvals_on' do
    before(:each) do
      subject.approvals_on
    end

    it 'enables the record level approval queue' do
      subject.approvals_on?.should be_true
    end
  end

  describe '#approvals_on?' do
    context 'when approval queues are enabled locally' do
      before(:each) do
        subject.instance_variable_set('@approvals_disabled', false)
      end

      it 'returns true' do
        subject.approvals_on?.should be_true
      end

      it 'ignores the model level status' do
        subject.stub(:model_approvals_on? => false)
        subject.approvals_on?.should be_true
      end

      it 'ignores the global level status' do
        subject.stub(:global_approvals_on? => false)
        subject.approvals_on?.should be_true
      end
    end

    context 'when approval queues are disabled locally' do
      before(:each) do
        subject.instance_variable_set('@approvals_disabled', true)
      end

      it 'returns false' do
        subject.approvals_on?.should be_false
      end

      it 'ignores the model level status' do
        subject.stub(:model_approvals_on? => true)
        subject.approvals_on?.should be_false
      end

      it 'ignores the global level status' do
        subject.stub(:global_approvals_on? => true)
        subject.approvals_on?.should be_false
      end
    end
  end

  describe '#approvable_on?' do
    it { should be_approvable_on(:create) }
    it { should be_approvable_on(:update) }

    context 'when the model is approvable on :create events' do
      subject { CreatesApprovable.new }

      it { should be_approvable_on(:create) }
      it { should_not be_approvable_on(:update) }
    end

    context 'when the model is approvable on :update events' do
      subject { UpdatesApprovable.new }

      it { should be_approvable_on(:update) }
      it { should_not be_approvable_on(:create) }
    end
  end

  context 'with approval and rejection hooks' do
    before(:each) do
      @record = CreatesApprovable.create

      @approval = @record.approval
      @approval.stub(:item => @record)
    end

    describe '#before_approve' do
      before(:each) do
        @record.stub(:before_approve => true)
      end

      it 'is called when approving a record' do
        @record.should_receive(:before_approve).and_return(true)
        @approval.approve!
      end

      it 'is not called when rejecting a record' do
        @record.should_not_receive(:before_approve)
        @approval.reject!
      end

      it 'receives the approval as an argument' do
        @record.should_receive(:before_approve).with(@approval).and_return(true)
        @approval.approve!
      end

      context 'when it returns false' do
        before(:each) do
          @record.stub(:before_approve => false)
        end

        it 'prevents the approval from proceeding' do
          @approval.approve!
          @approval.state.should == 'pending'
        end
      end
    end

    describe '#before_reject' do
      before(:each) do
        @record.stub(:before_reject => true)
      end

      it 'is called when rejecting a record' do
        @record.should_receive(:before_reject).and_return(true)
        @approval.reject!
      end

      it 'is not called when approving a record' do
        @record.should_not_receive(:before_reject)
        @approval.approve!
      end

      it 'receives the approval as an argument' do
        @record.should_receive(:before_reject).with(@approval).and_return(true)
        @approval.reject!
      end

      context 'when it returns false' do
        before(:each) do
          @record.stub(:before_reject => false)
        end

        it 'prevents the rejection from proceeding' do
          @approval.reject!
          @approval.state.should == 'pending'
        end
      end
    end

    describe '#after_approve' do
      it 'is called when approving a record' do
        @record.should_receive(:before_approve)
        @approval.approve!
      end

      it 'is not called when rejecting a record' do
        @record.should_not_receive(:after_approve)
        @approval.reject!
      end

      it 'receives the approval as an argument' do
        @record.should_receive(:after_approve).with(@approval).and_return(true)
        @approval.approve!
      end
    end

    describe '#after_reject' do
      it 'is called when rejecting a record' do
        @record.should_receive(:after_reject).and_return(true)
        @approval.reject!
      end

      it 'is not called when approving a record' do
        @record.should_not_receive(:after_reject)
        @approval.approve!
      end

      it 'receives the approval as an argument' do
        @record.should_receive(:after_reject).with(@approval).and_return(true)
        @approval.reject!
      end
    end
  end

  describe '#without_approval' do
    around(:each) do
      subject.approvals_on
    end

    it 'disables approval queues' do
      subject.without_approval { |r| r.update_attributes(:title => 'no review') }
      subject.update_approvals.should be_empty
    end

    it 'enables the approval queue after running' do
      subject.should be_approvals_on
      subject.without_approval { |r| r.update_attributes(:title => 'no review') }
      subject.should be_approvals_on
    end

    it 'returns the approval queue to the previous state' do
      subject.approvals_off
      subject.without_approval { |r| r.update_attributes(:title => 'no review') }
      subject.should_not be_approvals_on
    end
  end

  describe '#save_without_approval' do
    it 'calls #without_approval' do
      subject.should_receive(:without_approval)
      subject.save_without_approval
    end
  end

  describe '#save_without_approval!' do
    it 'calls #without_approval' do
      subject.should_receive(:without_approval)
      subject.save_without_approval!
    end
  end
end
