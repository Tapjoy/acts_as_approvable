require 'spec_helper'

describe Approval do
  before(:each) do
    subject.stub(:save! => true, :save => true)
  end

  it 'should serialize :object' do
    described_class.serialized_attributes.keys.should include('object')
  end

  describe '.associations' do
    it { should belong_to(:item) }
  end

  describe '.validates' do
    it { should validate_presence_of(:item) }
    it { should validate_inclusion_of(:event).in(%w(create update)) }
    it { should validate_numericality_of(:state) }
    it { should ensure_inclusion_of(:state).in_range(0..(described_class::STATES.length - 1)).with_low_message(/greater than/).with_high_message(/less than/)}
  end

  describe '.enumerate_state' do
    it 'enumerates "pending" to 0' do
      described_class.enumerate_state('pending').should be(0)
    end

    it 'enumerates "approved" to 1' do
      described_class.enumerate_state('approved').should be(1)
    end

    it 'enumerates "rejected" to 2' do
      described_class.enumerate_state('rejected').should be(2)
    end

    it 'enumerates other values to nil' do
      described_class.enumerate_state('not_a_state').should_not be
    end
  end

  describe '.enumerate_states' do
    it 'enumerates many states at once' do
      described_class.enumerate_states('pending', 'approved', 'rejected').should == [0, 1, 2]
    end

    it 'ignores states it does not know' do
      described_class.enumerate_states('pending', 'not_a_state', 'rejected').should == [0, 2]
    end
  end

  describe '.options_for_state' do
    it 'returns an array usable by #options_for_select' do
      described_class.options_for_state.should be_an_options_array
    end

    it 'includes an "all" option' do
      described_class.options_for_state.should include(['All', -1])
    end

    it 'includes the pending state' do
      described_class.options_for_state.should include(['Pending', 0])
    end

    it 'includes the approved state' do
      described_class.options_for_state.should include(['Approved', 1])
    end

    it 'includes the rejected state' do
      described_class.options_for_state.should include(['Rejected', 2])
    end
  end

  describe '.options_for_type' do
    before(:each) do
      @default = DefaultApprovable.create
      @creates = CreatesApprovable.create
      @updates = UpdatesApprovable.create
    end

    it 'returns an array usable by #options_for_select' do
      described_class.options_for_type.should be_an_options_array
    end

    it 'includes all types with approvals' do
      described_class.options_for_type.should include('DefaultApprovable')
      described_class.options_for_type.should include('CreatesApprovable')
    end

    it 'does not include types without approvals' do
      described_class.options_for_type.should_not include('UpdatesApprovable')
    end

    it 'includes a prompt if requested' do
      described_class.options_for_type(true).should include(['All Types', nil])
    end

    it 'does not includes a prompt by default' do
      described_class.options_for_type.should_not include(['All Types', nil])
    end
  end

  describe '#state' do
    it 'returns the state as a string' do
      subject.state.should be_a(String)
    end

    it 'attempts to read the state attribute' do
      subject.should_receive(:read_attribute).with(:state)
      subject.state
    end
  end

  describe '#state_was' do
    it 'returns the state as a string' do
      subject.state_was.should be_a(String)
    end

    it 'attempts to read the changed state attribute' do
      subject.should_receive(:changed_attributes).and_return({:state => 1})
      subject.state_was.should == 'approved'
    end
  end

  describe '#state=' do
    it 'writes the attribute value' do
      subject.should_receive(:write_attribute)
      subject.send(:state=, 'pending')
    end

    it 'enumerates the given state' do
      subject.should_receive(:write_attribute).with(:state, 0)
      subject.send(:state=, 'pending')
    end

    it 'skips enumeration for numeric values' do
      subject.should_receive(:write_attribute).with(:state, 10)
      subject.send(:state=, 10)
    end
  end

  context 'when the state is pending' do
    before(:each) do
      subject.stub(:state => 'pending')
    end

    it { should be_pending }
    it { should_not be_approved }
    it { should_not be_rejected }
    it { should_not be_locked }
    it { should be_unlocked }
  end

  context 'when the state is approved' do
    before(:each) do
      subject.stub(:state => 'approved')
    end

    it { should_not be_pending }
    it { should be_approved }
    it { should_not be_rejected }
    it { should be_locked }
    it { should_not be_unlocked }
  end

  context 'when the state is rejected' do
    before(:each) do
      subject.stub(:state => 'rejected')
    end

    it { should_not be_pending }
    it { should_not be_approved }
    it { should be_rejected }
    it { should be_locked }
    it { should_not be_unlocked }
  end

  context 'when the event is :update' do
    before(:each) do
      subject.stub(:event => 'update')
    end

    it { should be_update }
    it { should_not be_create }

    describe '#reset!' do
      it 'should raise an InvalidTransition error' do
        expect { subject.reset! }.to raise_error(ActsAsApprovable::Error::InvalidTransition)
      end
    end
  end

  context 'when the event is :create' do
    before(:each) do
      subject.stub(:event => 'create')
    end

    it { should_not be_update }
    it { should be_create }

    describe '#reset!' do
      it 'should not raise an InvalidTransition error' do
        expect { subject.reset! }.not_to raise_error(ActsAsApprovable::Error::InvalidTransition)
      end

      it 'should save even if no values change' do
        subject.stub(:item => DefaultApprovable.new)
        subject.should_receive(:save!).and_return(true)
        subject.reset!
      end
    end
  end

  context 'when the approval is unlocked' do
    before(:each) do
      @item = DefaultApprovable.without_approval { |m| m.create }
      subject.stub(:locked? => false, :updated_at => Time.now, :item => @item)
      @item.stub(:updated_at => Time.now)
    end

    describe '#able_to_save?' do
      it { should be_able_to_save }

      it 'does not check the what the state was' do
        subject.should_not_receive(:state_was)
        subject.able_to_save?
      end
    end

    describe '#stale?' do
      it 'checks when the item was changed' do
        @item.should_receive(:has_attribute?).with(:updated_at).and_return(true)
        subject.stale?
      end
    end

    describe '#fresh?' do
      it 'checks when the item was changed' do
        @item.should_receive(:has_attribute?).with(:updated_at).and_return(true)
        subject.fresh?
      end
    end

    describe '#reset!' do
      before(:each) do
        subject.stub(:event => 'create')
      end

      it 'saves the approval record' do
        subject.should_receive(:save!).and_return(true)
        subject.reset!
      end

      it 'changes the item state' do
        @item.should_receive(:set_approval_state).with('pending')
        subject.reset!
      end
    end

    context 'when the approval is newer than the last update' do
      before(:each) do
        subject.stub(:updated_at => @item.updated_at + 60)
      end

      it { should_not be_stale }
      it { should be_fresh }
    end

    context 'when the approval is older than the last update' do
      before(:each) do
        subject.stub(:updated_at => @item.updated_at - 60)
      end

      it { should be_stale }
      it { should_not be_fresh }
    end
  end

  context 'when the approval is locked' do
    before(:each) do
      subject.stub(:locked? => true)
    end

    it { should_not be_stale }
    it { should be_fresh }

    describe '#able_to_save?' do
      it 'checks the what the state was' do
        subject.should_receive(:state_was)
        subject.able_to_save?
      end
    end

    describe '#stale?' do
      it 'does not check when the item was changed' do
        subject.should_not_receive(:item)
        subject.stale?
      end
    end

    describe '#fresh?' do
      it 'does not check when the item was changed' do
        subject.should_not_receive(:item)
        subject.fresh?
      end
    end

    describe '#approve!' do
      it 'raises a Locked exception' do
        expect { subject.approve! }.to raise_error(ActsAsApprovable::Error::Locked)
      end

      it 'leaves the approval in a pending state' do
        begin; subject.approve!; rescue ActsAsApprovable::Error::Locked; end
        subject.should be_pending
      end
    end

    describe '#reject!' do
      it 'raises a Locked exception' do
        expect { subject.reject! }.to raise_error(ActsAsApprovable::Error::Locked)
      end

      it 'leaves the approval in a pending state' do
        begin; subject.reject!; rescue ActsAsApprovable::Error::Locked; end
        subject.should be_pending
      end
    end

    context 'and the state is pending' do
      before(:each) do
        subject.stub(:state_was => 'pending')
      end

      it { should be_able_to_save }
    end

    context 'and the state is approved' do
      before(:each) do
        subject.stub(:state_was => 'approved')
      end

      it { should_not be_able_to_save }
    end

    context 'and the state is rejected' do
      before(:each) do
        subject.stub(:state_was => 'rejected')
      end

      it { should_not be_able_to_save }
    end
  end

  context 'when the approval is stale' do
    before(:each) do
      @item = DefaultApprovable.without_approval { |m| m.create }
      subject.stub(:stale? => true, :item => @item)
    end

    it { should be_stale }
    it { should_not be_fresh }

    describe '#approve!' do
      it 'raises a Stale exception' do
        expect { subject.approve! }.to raise_error(ActsAsApprovable::Error::Stale)
      end

      it 'leaves the approval in a pending state' do
        begin; subject.approve!; rescue ActsAsApprovable::Error::Stale; end
        subject.should be_pending
      end

      context 'when approval is forced' do
        it 'does not raise a Stale exception' do
          expect { subject.approve!(true) }.to_not raise_error(ActsAsApprovable::Error::Stale)
        end

        it 'leaves the approval in a pending state' do
          subject.approve!(true)
          subject.should be_approved
        end
      end
    end

    describe '#reject!' do
      it 'does not raise a Stale exception' do
        expect { subject.reject! }.to_not raise_error(ActsAsApprovable::Error::Stale)
      end

      it 'moves the approval to a rejected state' do
        subject.reject!
        subject.should be_rejected
      end
    end
  end

  context 'when the approval is unlocked and fresh' do
    before(:each) do
      @item = DefaultApprovable.without_approval { |m| m.create }
      subject.stub(:locked? => false, :stale? => false, :item => @item, :object => {})
    end

    it { should_not be_stale }
    it { should be_fresh }

    describe '#approve!' do
      it 'does not raise an exception' do
        expect { subject.approve! }.to_not raise_error
      end

      it 'moves the approval to an approved state' do
        subject.approve!
        subject.should be_approved
      end

      it 'calls the before and after callbacks' do
        subject.should_receive(:run_item_callback).with(:before_approve).once.and_return(true)
        subject.should_receive(:run_item_callback).with(:after_approve).once
        subject.approve!
      end

      context 'when the event is :update' do
        before(:each) do
          subject.stub(:event => 'update')
        end

        it 'sets the item attributes' do
          @item.should_receive(:attributes=)
          subject.approve!
        end

        it 'does not set the local item state' do
          @item.should_not_receive(:set_approval_state)
          subject.approve!
        end
      end

      context 'when the event is :create' do
        before(:each) do
          subject.stub(:event => 'create')
        end

        it 'does not set the item attributes' do
          @item.should_not_receive(:attributes=)
          subject.approve!
        end

        it 'sets the local item state' do
          @item.should_receive(:set_approval_state).with('approved')
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
        subject.should be_rejected
      end

      it 'sets the reason if given' do
        subject.reject!('reason')
        subject.reason.should == 'reason'
      end

      it 'calls the before and after callbacks' do
        subject.should_receive(:run_item_callback).with(:before_reject).once.and_return(true)
        subject.should_receive(:run_item_callback).with(:after_reject).once
        subject.reject!
      end

      context 'when the event is :update' do
        before(:each) do
          subject.stub(:event => 'update')
        end

        it 'does not set the item attributes' do
          @item.should_not_receive(:attributes=)
          subject.reject!
        end

        it 'does not set the local item state' do
          @item.should_not_receive(:set_approval_state)
          subject.reject!
        end
      end

      context 'when the event is :create' do
        before(:each) do
          subject.stub(:event => 'create')
        end

        it 'does not set the item attributes' do
          @item.should_not_receive(:attributes=)
          subject.reject!
        end

        it 'sets the local item state' do
          @item.should_receive(:set_approval_state).with('rejected')
          subject.reject!
        end
      end
    end
  end
end
