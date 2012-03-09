require 'spec_helper'

describe ActsAsApprovable::Model::CreateInstanceMethods do
  subject { CreatesApprovable.create }

  describe '#approval' do
    subject { CreatesApprovable.create } # Reverse the mocking for #approval

    it 'returns a :create approval' do
      subject.approval.event == :create
    end

    it 'returns the first :create approval' do
      duplicate = Approval.create(:item_id => subject.id, :item_type => 'CreatesApprovable', :event => 'create')
      subject.approval != duplicate
    end
  end

  context do
    before(:each) do
      @approval = subject.approvals.first
      subject.stub(:approval => @approval)
    end

    describe '#approval_state' do
      it 'gets the state from the approval record' do
        @approval.should_receive(:state)
        subject.approval_state
      end

      context 'when a :state_field is configured' do
        subject { CreatesWithStateApprovable.create }

        it 'gets the state from the configured field' do
          subject.should_receive(:state)
          subject.approval_state
        end

        it 'does not get the state from the approval record' do
          subject.should_not_receive(:approval)
          subject.approval_state
        end
      end
    end

    describe '#set_approval_state' do
      it 'does nothing if no :state_field is configured' do
        subject.should_not_receive(:state=)
        subject.set_approval_state('pending')
      end

      context 'when a :state_field is configured' do
        subject { CreatesWithStateApprovable.create }

        it 'sets the configured field' do
          subject.should_receive(:state=)
          subject.set_approval_state('pending')
        end
      end
    end

    describe '#pending?' do
      it 'gets the status from the approval record' do
        subject.should_receive(:approval)
        subject.pending?
      end

      context 'when a :state_field is configured' do
        subject { CreatesWithStateApprovable.create }

        it 'gets the state from the configured field' do
          subject.should_receive(:state)
          subject.pending?
        end

        it 'does not get the state from the approval record' do
          subject.should_not_receive(:approval)
          subject.pending?
        end
      end
    end

    describe '#approved?' do
      it 'gets the status from the approval record' do
        subject.should_receive(:approval)
        subject.approved?
      end

      context 'when a :state_field is configured' do
        subject { CreatesWithStateApprovable.create }

        it 'gets the state from the configured field' do
          subject.should_receive(:state)
          subject.approved?
        end

        it 'does not get the state from the approval record' do
          subject.should_not_receive(:approval)
          subject.approved?
        end
      end
    end

    describe '#rejected?' do
      it 'gets the status from the approval record' do
        subject.should_receive(:approval)
        subject.rejected?
      end

      context 'when a :state_field is configured' do
        subject { CreatesWithStateApprovable.create }

        it 'gets the state from the configured field' do
          subject.should_receive(:state)
          subject.rejected?
        end

        it 'does not get the state from the approval record' do
          subject.should_not_receive(:approval)
          subject.rejected?
        end
      end
    end

    describe '#approve!' do
      it 'approves the record' do
        subject.approve!
        subject.should be_approved
      end

      it 'proxies to the approval record for approval' do
        subject.should_receive(:approval)
        subject.approve!
      end
    end

    describe '#reject!' do
      it 'rejects the record' do
        subject.reject!
        subject.should be_rejected
      end

      it 'proxies to the approval record for approval' do
        subject.should_receive(:approval)
        subject.reject!
      end
    end
  end
end
