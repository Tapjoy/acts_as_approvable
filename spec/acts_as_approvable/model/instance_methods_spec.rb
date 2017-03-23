require 'spec_helper'

describe ActsAsApprovable::Model::InstanceMethods do
  subject { DefaultApprovable.new }

  describe '#approvals_enabled?' do
    before(:each) do
      allow(subject).to receive_messages(:global_approvals_on? => true)
      allow(subject).to receive_messages(:model_approvals_on? => true)
      allow(subject).to receive_messages(:approvals_on? => true)
    end

    context 'when approvals are globally disabled' do
      before(:each) do
        allow(subject).to receive_messages(:global_approvals_on? => false)
      end

      it 'returns false' do
        expect(subject.approvals_enabled?).to be_falsey
      end

      it 'checks the global status' do
        expect(subject).to receive(:global_approvals_on?).and_return(false)
        subject.approvals_enabled?
      end

      it 'does not check the model status' do
        expect(subject).not_to receive(:model_approvals_on?)
        subject.approvals_enabled?
      end

      it 'does not check the record status' do
        expect(subject).not_to receive(:approvals_on?)
        subject.approvals_enabled?
      end
    end

    context 'when approvals are disabled for the Model' do
      before(:each) do
        allow(subject).to receive_messages(:model_approvals_on? => false)
      end

      it 'returns false' do
        expect(subject.approvals_enabled?).to be_falsey
      end

      it 'checks the global status' do
        expect(subject).to receive(:global_approvals_on?).and_return(true)
        subject.approvals_enabled?
      end

      it 'checks the model status' do
        expect(subject).to receive(:model_approvals_on?).and_return(false)
        subject.approvals_enabled?
      end

      it 'does not check the record status' do
        expect(subject).not_to receive(:approvals_on?)
        subject.approvals_enabled?
      end
    end

    context 'when approvals are disabled for the Record' do
      before(:each) do
        allow(subject).to receive_messages(:approvals_on? => false)
      end

      it 'returns false' do
        expect(subject.approvals_enabled?).to be_falsey
      end

      it 'checks the global status' do
        expect(subject).to receive(:global_approvals_on?).and_return(true)
        subject.approvals_enabled?
      end

      it 'checks the model status' do
        expect(subject).to receive(:model_approvals_on?).and_return(true)
        subject.approvals_enabled?
      end

      it 'checks the record status' do
        expect(subject).to receive(:approvals_on?).and_return(false)
        subject.approvals_enabled?
      end
    end
  end

  describe '#approvals_disabled?' do
    before(:each) do
      allow(subject).to receive_messages(:approvals_enabled? => true)
    end

    it 'returns the inverse of the approval queue status' do
      expect(subject.approvals_disabled?).to eq(!subject.approvals_enabled?)
    end

    it 'calls #approvals_enabled? for the status' do
      expect(subject).to receive(:approvals_enabled?).and_return(true)
      subject.approvals_disabled?
    end
  end

  describe '#approvals_off' do
    before(:each) do
      subject.approvals_off
    end

    it 'disables the record level approval queue' do
      expect(subject.approvals_on?).to be_falsey
    end
  end

  describe '#approvals_on' do
    before(:each) do
      subject.approvals_on
    end

    it 'enables the record level approval queue' do
      expect(subject.approvals_on?).to be_truthy
    end
  end

  describe '#approvals_on?' do
    context 'when approval queues are enabled locally' do
      before(:each) do
        subject.instance_variable_set('@approvals_disabled', false)
      end

      it 'returns true' do
        expect(subject.approvals_on?).to be_truthy
      end

      it 'ignores the model level status' do
        allow(subject).to receive_messages(:model_approvals_on? => false)
        expect(subject.approvals_on?).to be_truthy
      end

      it 'ignores the global level status' do
        allow(subject).to receive_messages(:global_approvals_on? => false)
        expect(subject.approvals_on?).to be_truthy
      end
    end

    context 'when approval queues are disabled locally' do
      before(:each) do
        subject.instance_variable_set('@approvals_disabled', true)
      end

      it 'returns false' do
        expect(subject.approvals_on?).to be_falsey
      end

      it 'ignores the model level status' do
        allow(subject).to receive_messages(:model_approvals_on? => true)
        expect(subject.approvals_on?).to be_falsey
      end

      it 'ignores the global level status' do
        allow(subject).to receive_messages(:global_approvals_on? => true)
        expect(subject.approvals_on?).to be_falsey
      end
    end
  end

  describe '#approvable_on?' do
    it { is_expected.to be_approvable_on(:create) }
    it { is_expected.to be_approvable_on(:update) }

    context 'when the model is approvable on :create events' do
      subject { CreatesApprovable.new }

      it { is_expected.to be_approvable_on(:create) }
      it { is_expected.not_to be_approvable_on(:update) }
    end

    context 'when the model is approvable on :update events' do
      subject { UpdatesApprovable.new }

      it { is_expected.to be_approvable_on(:update) }
      it { is_expected.not_to be_approvable_on(:create) }
    end
  end

  context 'with approval and rejection hooks' do
    before(:each) do
      @record = CreatesApprovable.create

      @approval = @record.approval
      allow(@approval).to receive_messages(:item => @record)
    end

    describe '#before_approve' do
      before(:each) do
        allow(@record).to receive_messages(:before_approve => true)
      end

      it 'is called when approving a record' do
        expect(@record).to receive(:before_approve).and_return(true)
        @approval.approve!
      end

      it 'is not called when rejecting a record' do
        expect(@record).not_to receive(:before_approve)
        @approval.reject!
      end

      it 'receives the approval as an argument' do
        expect(@record).to receive(:before_approve).with(@approval).and_return(true)
        @approval.approve!
      end

      context 'when it returns false' do
        before(:each) do
          allow(@record).to receive_messages(:before_approve => false)
        end

        it 'prevents the approval from proceeding' do
          @approval.approve!
          expect(@approval.state).to eq('pending')
        end
      end
    end

    describe '#before_reject' do
      before(:each) do
        allow(@record).to receive_messages(:before_reject => true)
      end

      it 'is called when rejecting a record' do
        expect(@record).to receive(:before_reject).and_return(true)
        @approval.reject!
      end

      it 'is not called when approving a record' do
        expect(@record).not_to receive(:before_reject)
        @approval.approve!
      end

      it 'receives the approval as an argument' do
        expect(@record).to receive(:before_reject).with(@approval).and_return(true)
        @approval.reject!
      end

      context 'when it returns false' do
        before(:each) do
          allow(@record).to receive_messages(:before_reject => false)
        end

        it 'prevents the rejection from proceeding' do
          @approval.reject!
          expect(@approval.state).to eq('pending')
        end
      end
    end

    describe '#after_approve' do
      it 'is called when approving a record' do
        expect(@record).to receive(:before_approve)
        @approval.approve!
      end

      it 'is not called when rejecting a record' do
        expect(@record).not_to receive(:after_approve)
        @approval.reject!
      end

      it 'receives the approval as an argument' do
        expect(@record).to receive(:after_approve).with(@approval).and_return(true)
        @approval.approve!
      end
    end

    describe '#after_reject' do
      it 'is called when rejecting a record' do
        expect(@record).to receive(:after_reject).and_return(true)
        @approval.reject!
      end

      it 'is not called when approving a record' do
        expect(@record).not_to receive(:after_reject)
        @approval.approve!
      end

      it 'receives the approval as an argument' do
        expect(@record).to receive(:after_reject).with(@approval).and_return(true)
        @approval.reject!
      end
    end
  end

  describe '#without_approval' do
    before(:each) do
      subject.approvals_on
    end

    it 'disables approval queues' do
      subject.without_approval { |r| r.update_attributes(:title => 'no review') }
      expect(subject.update_approvals).to be_empty
    end

    it 'enables the approval queue after running' do
      expect(subject).to be_approvals_on
      subject.without_approval { |r| r.update_attributes(:title => 'no review') }
      expect(subject).to be_approvals_on
    end

    it 'returns the approval queue to the previous state' do
      subject.approvals_off
      subject.without_approval { |r| r.update_attributes(:title => 'no review') }
      expect(subject).not_to be_approvals_on
    end
  end

  describe '#save_without_approval' do
    it 'calls #without_approval' do
      expect(subject).to receive(:without_approval)
      subject.save_without_approval
    end
  end

  describe '#save_without_approval!' do
    it 'calls #without_approval' do
      expect(subject).to receive(:without_approval)
      subject.save_without_approval!
    end
  end
end
