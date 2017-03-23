require 'spec_helper'

describe Approval do
  before(:each) do
    allow(subject).to receive_messages(:save! => true, :save => true)
  end

  it 'should serialize :object' do
    expect(described_class.serialized_attributes.keys).to include('object')
  end

  describe '.associations' do
    it { is_expected.to belong_to(:item) }
  end

  describe '.validates' do
    it { is_expected.to validate_presence_of(:item) }
    it { is_expected.to validate_inclusion_of(:event).in_array(%w(create update)) }
    it { is_expected.to validate_numericality_of(:state) }
    it { is_expected.to ensure_inclusion_of(:state).in_range(0..(described_class::STATES.length - 1)).with_low_message(/greater than/).with_high_message(/less than/)}
  end

  describe '.enumerate_state' do
    it 'enumerates "pending" to 0' do
      expect(described_class.enumerate_state('pending')).to be(0)
    end

    it 'enumerates "approved" to 1' do
      expect(described_class.enumerate_state('approved')).to be(1)
    end

    it 'enumerates "rejected" to 2' do
      expect(described_class.enumerate_state('rejected')).to be(2)
    end

    it 'enumerates other values to nil' do
      expect(described_class.enumerate_state('not_a_state')).not_to be
    end
  end

  describe '.enumerate_states' do
    it 'enumerates many states at once' do
      expect(described_class.enumerate_states('pending', 'approved', 'rejected')).to eq([0, 1, 2])
    end

    it 'ignores states it does not know' do
      expect(described_class.enumerate_states('pending', 'not_a_state', 'rejected')).to eq([0, 2])
    end
  end

  describe '.options_for_state' do
    it 'returns an array usable by #options_for_select' do
      expect(described_class.options_for_state).to be_an_options_array
    end

    it 'includes an "all" option' do
      expect(described_class.options_for_state).to include(['All', -1])
    end

    it 'includes the pending state' do
      expect(described_class.options_for_state).to include(['Pending', 0])
    end

    it 'includes the approved state' do
      expect(described_class.options_for_state).to include(['Approved', 1])
    end

    it 'includes the rejected state' do
      expect(described_class.options_for_state).to include(['Rejected', 2])
    end
  end

  describe '.options_for_type' do
    before(:each) do
      @default = DefaultApprovable.create
      @creates = CreatesApprovable.create
      @updates = UpdatesApprovable.create
    end

    it 'returns an array usable by #options_for_select' do
      expect(described_class.options_for_type).to be_an_options_array
    end

    it 'includes all types with approvals' do
      expect(described_class.options_for_type).to include('DefaultApprovable')
      expect(described_class.options_for_type).to include('CreatesApprovable')
    end

    it 'does not include types without approvals' do
      expect(described_class.options_for_type).not_to include('UpdatesApprovable')
    end

    it 'includes a prompt if requested' do
      expect(described_class.options_for_type(true)).to include(['All Types', nil])
    end

    it 'does not includes a prompt by default' do
      expect(described_class.options_for_type).not_to include(['All Types', nil])
    end
  end

  describe '#state' do
    it 'returns the state as a string' do
      expect(subject.state).to be_a(String)
    end

    it 'attempts to read the state attribute' do
      expect(subject).to receive(:read_attribute).with(:state)
      subject.state
    end
  end

  describe '#state_was' do
    it 'returns the state as a string' do
      expect(subject.state_was).to be_a(String)
    end

    it 'attempts to read the changed state attribute' do
      expect(subject).to receive(:changed_attributes).and_return({:state => 1})
      expect(subject.state_was).to eq('approved')
    end
  end

  describe '#state=' do
    it 'writes the attribute value' do
      expect(subject).to receive(:write_attribute)
      subject.send(:state=, 'pending')
    end

    it 'enumerates the given state' do
      expect(subject).to receive(:write_attribute).with(:state, 0)
      subject.send(:state=, 'pending')
    end

    it 'skips enumeration for numeric values' do
      expect(subject).to receive(:write_attribute).with(:state, 10)
      subject.send(:state=, 10)
    end
  end

  context 'when the state is pending' do
    before(:each) do
      allow(subject).to receive_messages(:state => 'pending')
    end

    it { is_expected.to be_pending }
    it { is_expected.not_to be_approved }
    it { is_expected.not_to be_rejected }
    it { is_expected.not_to be_locked }
    it { is_expected.to be_unlocked }
  end

  context 'when the state is approved' do
    before(:each) do
      allow(subject).to receive_messages(:state => 'approved')
    end

    it { is_expected.not_to be_pending }
    it { is_expected.to be_approved }
    it { is_expected.not_to be_rejected }
    it { is_expected.to be_locked }
    it { is_expected.not_to be_unlocked }
  end

  context 'when the state is rejected' do
    before(:each) do
      allow(subject).to receive_messages(:state => 'rejected')
    end

    it { is_expected.not_to be_pending }
    it { is_expected.not_to be_approved }
    it { is_expected.to be_rejected }
    it { is_expected.to be_locked }
    it { is_expected.not_to be_unlocked }
  end

  context 'when the event is :update' do
    before(:each) do
      allow(subject).to receive_messages(:event => 'update')
    end

    it { is_expected.to be_update }
    it { is_expected.not_to be_create }
    it { is_expected.not_to be_destroy }

    describe '#reset!' do
      it 'should raise an InvalidTransition error' do
        expect { subject.reset! }.to raise_error(ActsAsApprovable::Error::InvalidTransition)
      end
    end
  end

  context 'when the event is :create' do
    before(:each) do
      allow(subject).to receive_messages(:event => 'create')
    end

    it { is_expected.not_to be_update }
    it { is_expected.to be_create }
    it { is_expected.not_to be_destroy }

    describe '#reset!' do
      it 'should not raise an InvalidTransition error' do
        expect { subject.reset! }.not_to raise_error(ActsAsApprovable::Error::InvalidTransition)
      end

      it 'should save even if no values change' do
        allow(subject).to receive_messages(:item => DefaultApprovable.new)
        expect(subject).to receive(:save!).and_return(true)
        subject.reset!
      end
    end
  end

  context 'when the event is :destroy' do
    before(:each) do
      allow(subject).to receive_messages(:event => 'destroy')
    end

    it { is_expected.not_to be_update }
    it { is_expected.not_to be_create }
    it { is_expected.to be_destroy }
  end

  context 'when the approval is unlocked' do
    before(:each) do
      @item = DefaultApprovable.without_approval { |m| m.create }
      allow(subject).to receive_messages(:locked? => false, :updated_at => Time.now, :item => @item)
      allow(@item).to receive_messages(:updated_at => Time.now)
    end

    describe '#able_to_save?' do
      it { is_expected.to be_able_to_save }

      it 'does not check the what the state was' do
        expect(subject).not_to receive(:state_was)
        subject.able_to_save?
      end
    end

    describe '#stale?' do
      it 'checks when the item was changed' do
        expect(@item).to receive(:has_attribute?).with(:updated_at).and_return(true)
        subject.stale?
      end
    end

    describe '#fresh?' do
      it 'checks when the item was changed' do
        expect(@item).to receive(:has_attribute?).with(:updated_at).and_return(true)
        subject.fresh?
      end
    end

    describe '#reset!' do
      before(:each) do
        allow(subject).to receive_messages(:event => 'create')
      end

      it 'saves the approval record' do
        expect(subject).to receive(:save!).and_return(true)
        subject.reset!
      end

      it 'changes the item state' do
        expect(@item).to receive(:set_approval_state).with('pending')
        subject.reset!
      end
    end

    context 'when the approval is newer than the last update' do
      before(:each) do
        allow(subject).to receive_messages(:updated_at => @item.updated_at + 60)
      end

      it { is_expected.not_to be_stale }
      it { is_expected.to be_fresh }
    end

    context 'when the approval is older than the last update' do
      before(:each) do
        allow(subject).to receive_messages(:updated_at => @item.updated_at - 60)
      end

      it { is_expected.to be_stale }
      it { is_expected.not_to be_fresh }
    end
  end

  context 'when the approval is locked' do
    before(:each) do
      allow(subject).to receive_messages(:locked? => true)
    end

    it { is_expected.not_to be_stale }
    it { is_expected.to be_fresh }

    describe '#able_to_save?' do
      it 'checks the what the state was' do
        expect(subject).to receive(:state_was)
        subject.able_to_save?
      end
    end

    describe '#stale?' do
      it 'does not check when the item was changed' do
        expect(subject).not_to receive(:item)
        subject.stale?
      end
    end

    describe '#fresh?' do
      it 'does not check when the item was changed' do
        expect(subject).not_to receive(:item)
        subject.fresh?
      end
    end

    describe '#approve!' do
      it 'raises a Locked exception' do
        expect { subject.approve! }.to raise_error(ActsAsApprovable::Error::Locked)
      end

      it 'leaves the approval in a pending state' do
        begin; subject.approve!; rescue ActsAsApprovable::Error::Locked; end
        expect(subject).to be_pending
      end
    end

    describe '#reject!' do
      it 'raises a Locked exception' do
        expect { subject.reject! }.to raise_error(ActsAsApprovable::Error::Locked)
      end

      it 'leaves the approval in a pending state' do
        begin; subject.reject!; rescue ActsAsApprovable::Error::Locked; end
        expect(subject).to be_pending
      end
    end

    context 'and the state is pending' do
      before(:each) do
        allow(subject).to receive_messages(:state_was => 'pending')
      end

      it { is_expected.to be_able_to_save }
    end

    context 'and the state is approved' do
      before(:each) do
        allow(subject).to receive_messages(:state_was => 'approved')
      end

      it { is_expected.not_to be_able_to_save }
    end

    context 'and the state is rejected' do
      before(:each) do
        allow(subject).to receive_messages(:state_was => 'rejected')
      end

      it { is_expected.not_to be_able_to_save }
    end
  end

  context 'when the approval is stale' do
    before(:each) do
      @item = DefaultApprovable.without_approval { |m| m.create }
      allow(subject).to receive_messages(:stale? => true, :item => @item)
    end

    it { is_expected.to be_stale }
    it { is_expected.not_to be_fresh }

    describe '#approve!' do
      context 'with an :update approval' do
        before(:each) do
          allow(subject).to receive_messages(:event => 'update', :object => [])
        end

        it 'raises a Stale exception' do
          expect { subject.approve! }.to raise_error(ActsAsApprovable::Error::Stale)
        end

        it 'leaves the approval in a pending state' do
          begin; subject.approve!; rescue ActsAsApprovable::Error::Stale; end
          expect(subject).to be_pending
        end

        context 'when the stale check is disabled' do
          before(:each) do
            allow(ActsAsApprovable).to receive_messages(:stale_check? => false)
          end

          it 'does not raise a Stale exception' do
            expect { subject.approve!(true) }.to_not raise_error
          end
        end

        context 'when approval is forced' do
          it 'does not raise a Stale exception' do
            expect { subject.approve!(true) }.to_not raise_error
          end

          it 'leaves the approval in a pending state' do
            subject.approve!(true)
            expect(subject).to be_approved
          end
        end
      end

      context 'with a :create approval' do
        before(:each) do
          allow(subject).to receive_messages(:event => 'create')
        end

        it 'does not raise a Stale exception' do
          expect { subject.approve! }.to_not raise_error
        end

        it 'changes the approval to approved' do
          subject.approve!
          expect(subject).to be_approved
        end
      end
    end

    describe '#reject!' do
      it 'does not raise a Stale exception' do
        expect { subject.reject! }.to_not raise_error
      end

      it 'moves the approval to a rejected state' do
        subject.reject!
        expect(subject).to be_rejected
      end
    end
  end

  context 'when the approval is unlocked and fresh' do
    before(:each) do
      @item = DefaultApprovable.without_approval { |m| m.create }
      allow(subject).to receive_messages(:locked? => false, :stale? => false, :item => @item, :object => {})
    end

    it { is_expected.not_to be_stale }
    it { is_expected.to be_fresh }

    describe '#approve!' do
      it 'does not raise an exception' do
        expect { subject.approve! }.to_not raise_error
      end

      it 'moves the approval to an approved state' do
        subject.approve!
        expect(subject).to be_approved
      end

      it 'calls the before and after callbacks' do
        expect(subject).to receive(:run_item_callback).with(:before_approve).once.and_return(true)
        expect(subject).to receive(:run_item_callback).with(:after_approve).once
        subject.approve!
      end

      context 'when the event is :update' do
        before(:each) do
          allow(subject).to receive_messages(:event => 'update')
        end

        it 'sets the item attributes' do
          expect(@item).to receive(:attributes=)
          subject.approve!
        end

        it 'does not set the local item state' do
          expect(@item).not_to receive(:set_approval_state)
          subject.approve!
        end

        it 'does not destroy the item' do
          expect(@item).not_to receive(:destroy)
          subject.approve!
        end
      end

      context 'when the event is :create' do
        before(:each) do
          allow(subject).to receive_messages(:event => 'create')
        end

        it 'does not set the item attributes' do
          expect(@item).not_to receive(:attributes=)
          subject.approve!
        end

        it 'sets the local item state' do
          expect(@item).to receive(:set_approval_state).with('approved')
          subject.approve!
        end

        it 'does not destroy the item' do
          expect(@item).not_to receive(:destroy)
          subject.approve!
        end
      end

      context 'when the event is :destroy' do
        before(:each) do
          allow(subject).to receive_messages(:event => 'destroy')
        end

        it 'does not set the item attributes' do
          expect(@item).not_to receive(:attributes=)
          subject.approve!
        end

        it 'does not set the local item state' do
          expect(@item).not_to receive(:set_approval_state)
          subject.approve!
        end

        it 'destroys the item' do
          expect(@item).to receive(:destroy)
          subject.approve!
        end
      end
    end

    describe '#reject!' do
      it 'does not raise an exception' do
        expect { subject.reject! }.to_not raise_error
      end

      it 'moves the approval to a rejected state' do
        subject.reject!
        expect(subject).to be_rejected
      end

      it 'sets the reason if given' do
        subject.reject!('reason')
        expect(subject.reason).to eq('reason')
      end

      it 'calls the before and after callbacks' do
        expect(subject).to receive(:run_item_callback).with(:before_reject).once.and_return(true)
        expect(subject).to receive(:run_item_callback).with(:after_reject).once
        subject.reject!
      end

      context 'when the event is :update' do
        before(:each) do
          allow(subject).to receive_messages(:event => 'update')
        end

        it 'does not set the item attributes' do
          expect(@item).not_to receive(:attributes=)
          subject.reject!
        end

        it 'does not set the local item state' do
          expect(@item).not_to receive(:set_approval_state)
          subject.reject!
        end

        it 'does not destroy the item' do
          expect(@item).not_to receive(:destroy)
          subject.reject!
        end
      end

      context 'when the event is :create' do
        before(:each) do
          allow(subject).to receive_messages(:event => 'create')
        end

        it 'does not set the item attributes' do
          expect(@item).not_to receive(:attributes=)
          subject.reject!
        end

        it 'sets the local item state' do
          expect(@item).to receive(:set_approval_state).with('rejected')
          subject.reject!
        end

        it 'does not destroy the item' do
          expect(@item).not_to receive(:destroy)
          subject.reject!
        end
      end

      context 'when the event is :destroy' do
        before(:each) do
          allow(subject).to receive_messages(:event => 'destroy')
        end

        it 'does not set the item attributes' do
          expect(@item).not_to receive(:attributes=)
          subject.reject!
        end

        it 'does not set the local item state' do
          expect(@item).not_to receive(:set_approval_state)
          subject.reject!
        end

        it 'does not destroy the item' do
          expect(@item).not_to receive(:destroy)
          subject.reject!
        end
      end
    end
  end
end
