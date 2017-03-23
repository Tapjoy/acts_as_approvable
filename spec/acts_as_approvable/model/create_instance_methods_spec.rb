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
      allow(subject).to receive_messages(:approval => @approval)
    end

    describe '#approval_state' do
      it 'gets the state from the approval record' do
        expect(@approval).to receive(:state)
        subject.approval_state
      end

      context 'when a :state_field is configured' do
        subject { CreatesWithStateApprovable.create }

        it 'gets the state from the configured field' do
          expect(subject).to receive(:state)
          subject.approval_state
        end

        it 'does not get the state from the approval record' do
          expect(subject).not_to receive(:approval)
          subject.approval_state
        end
      end
    end

    describe '#set_approval_state' do
      it 'does nothing if no :state_field is configured' do
        expect(subject).not_to receive(:state=)
        subject.set_approval_state('pending')
      end

      context 'when a :state_field is configured' do
        subject { CreatesWithStateApprovable.create }

        it 'sets the configured field' do
          expect(subject).to receive(:state=)
          subject.set_approval_state('pending')
        end
      end
    end

    describe '#pending?' do
      it 'gets the status from the approval record' do
        expect(subject).to receive(:approval)
        subject.pending?
      end

      context 'when a :state_field is configured' do
        subject { CreatesWithStateApprovable.create }

        it 'gets the state from the configured field' do
          expect(subject).to receive(:state)
          subject.pending?
        end

        it 'does not get the state from the approval record' do
          expect(subject).not_to receive(:approval)
          subject.pending?
        end
      end
    end

    describe '#approved?' do
      it 'gets the status from the approval record' do
        expect(subject).to receive(:approval)
        subject.approved?
      end

      context 'when a :state_field is configured' do
        subject { CreatesWithStateApprovable.create }

        it 'gets the state from the configured field' do
          expect(subject).to receive(:state)
          subject.approved?
        end

        it 'does not get the state from the approval record' do
          expect(subject).not_to receive(:approval)
          subject.approved?
        end
      end
    end

    describe '#rejected?' do
      it 'gets the status from the approval record' do
        expect(subject).to receive(:approval)
        subject.rejected?
      end

      context 'when a :state_field is configured' do
        subject { CreatesWithStateApprovable.create }

        it 'gets the state from the configured field' do
          expect(subject).to receive(:state)
          subject.rejected?
        end

        it 'does not get the state from the approval record' do
          expect(subject).not_to receive(:approval)
          subject.rejected?
        end
      end
    end

    describe '#approve!' do
      it 'approves the record' do
        subject.approve!
        expect(subject).to be_approved
      end

      it 'proxies to the approval record for approval' do
        expect(subject).to receive(:approval)
        subject.approve!
      end
    end

    describe '#reject!' do
      it 'rejects the record' do
        subject.reject!
        expect(subject).to be_rejected
      end

      it 'proxies to the approval record for approval' do
        expect(subject).to receive(:approval)
        subject.reject!
      end
    end

    describe '#reset!' do
      it 'proxies to the approval record for approval' do
        expect(subject).to receive(:approval)
        subject.reset!
      end

      context 'when the approval is stale' do
        before(:each) do
          subject.approval.class.record_timestamps = false
          subject.approval.update_attribute(:updated_at, subject.approval.updated_at - 1)
          subject.approval.class.record_timestamps = true
        end

        it 'puts the approval back to fresh' do
          subject.reset!
          expect(subject.approval).to be_fresh
        end
      end
    end
  end
end
