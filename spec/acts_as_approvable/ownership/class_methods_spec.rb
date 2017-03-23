require 'spec_helper'

describe ActsAsApprovable::Ownership::ClassMethods do
  before(:all) do
    ActsAsApprovable::Ownership.configure
  end

  before(:each) do
    @user1 = User.create
    @user2 = User.create
  end

  subject { Approval }

  describe '.owner_class' do
    it 'proxies to ActsAsApprovable' do
      expect(ActsAsApprovable).to receive(:owner_class)
      subject.owner_class
    end
  end

  describe '.owner_source' do
    it 'proxies to ActsAsApprovable' do
      expect(ActsAsApprovable).to receive(:owner_source)
      subject.owner_source
    end
  end

  describe '.available_owners' do
    it 'selects all records from #owner_class' do
      expect(subject.available_owners).to include(@user1)
      expect(subject.available_owners).to include(@user2)
    end

    context 'when an owner source is configured' do
      before(:each) do
        class FakeSource; end
        ActsAsApprovable.owner_source = FakeSource
      end

      it 'proxies to the configured source' do
        expect(FakeSource).to receive(:available_owners)
        subject.available_owners
      end
    end
  end

  describe '.options_for_available_owners' do
    it 'returns an array usable by #options_for_select' do
      expect(subject.options_for_available_owners).to be_an_options_array
    end

    it 'uses .available_owners as its source' do
      expect(subject).to receive(:available_owners).and_return([])
      subject.options_for_available_owners
    end

    it 'uses .options_for_owner to format each record' do
      expect(subject).to receive(:option_for_owner).with(@user1).once
      expect(subject).to receive(:option_for_owner).with(@user2).once
      subject.options_for_available_owners
    end

    it 'includes a prompt if requested' do
      expect(subject.options_for_available_owners(true)).to include(['(none)', nil])
    end

    it 'does not includes a prompt by default' do
      expect(subject.options_for_available_owners).not_to include(['(none)', nil])
    end
  end

  context 'when an owner source is configured' do
    before(:each) do
      class FakeSource; end
      ActsAsApprovable.owner_source = FakeSource
    end

    describe '.assigned_owners' do
      it 'proxies to the configured source' do
        expect(FakeSource).to receive(:assigned_owners)
        subject.assigned_owners
      end
    end
  end

  context 'when no users are assigned' do
    describe '.assigned_owners' do
      it 'should be empty' do
        expect(subject.assigned_owners).to be_empty
      end
    end
  end

  context 'when some users are assigned' do
    before(:each) do
      CreatesApprovable.create.approval.update_attribute(:owner_id, @user1.id)
    end

    describe '.assigned_owners' do
      it 'selects all owners with an assigned approval' do
        expect(subject.assigned_owners).to include(@user1)
      end

      it 'does not include owners without an assignment' do
        expect(subject.assigned_owners).not_to include(@user2)
      end
    end

    describe '.options_for_assigned_owners' do
      it 'returns an array usable by #options_for_select' do
        expect(subject.options_for_assigned_owners).to be_an_options_array
      end

      it 'uses .assigned_owners as its source' do
        expect(subject).to receive(:assigned_owners).and_return([@user1])
        subject.options_for_assigned_owners
      end

      it 'uses .options_for_owner to format each record' do
        expect(subject).to receive(:option_for_owner).with(@user1)
        subject.options_for_assigned_owners
      end

      it 'includes a prompt if requested' do
        expect(subject.options_for_assigned_owners(true)).to include(['All Users', nil])
      end

      it 'does not includes a prompt by default' do
        expect(subject.options_for_assigned_owners).not_to include(['All Users', nil])
      end
    end
  end
end
