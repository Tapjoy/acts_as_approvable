require 'spec_helper'

describe ActsAsApprovable::Model::ClassMethods do
  subject { DefaultApprovable }

  describe '.acts_as_approvable' do
    subject do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'nots'
      end
    end

    it 'includes InstanceMethods into the class' do
      expect(subject).not_to extend(ActsAsApprovable::Model::InstanceMethods)
      subject.acts_as_approvable
      expect(subject).to extend(ActsAsApprovable::Model::InstanceMethods)
    end

    it 'includes ClassMethods into the class' do
      expect(subject).not_to extend(ActsAsApprovable::Model::ClassMethods)
      subject.acts_as_approvable
      expect(subject).to extend(ActsAsApprovable::Model::ClassMethods)
    end
  end

  describe '.approvals_enabled?' do
    before(:each) do
      allow(subject).to receive_messages(:global_approvals_on? => true)
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
        expect(subject).not_to receive(:approvals_on?)
        subject.approvals_enabled?
      end
    end

    context 'when approvals are disabled for the Model' do
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
        expect(subject).to receive(:approvals_on?).and_return(false)
        subject.approvals_enabled?
      end
    end
  end

  describe '.approvals_disabled?' do
    before(:each) do
      allow(subject).to receive_messages(:approvals_enabled? => true)
    end

    it 'returns the inverse of the approval queue status' do
      expect(subject.approvals_disabled?).to eq(!subject.approvals_enabled?)
    end

    it 'calls .approvals_enabled? for the status' do
      expect(subject).to receive(:approvals_enabled?).and_return(true)
      subject.approvals_disabled?
    end
  end

  describe '.approvals_off' do
    before(:each) do
      subject.approvals_off
    end

    it 'disables the model level approval queue' do
      expect(subject.approvals_on?).to be_falsey
    end
  end

  describe '.approvals_on' do
    before(:each) do
      subject.approvals_on
    end

    it 'enables the model level approval queue' do
      expect(subject.approvals_on?).to be_truthy
    end
  end

  describe '.approvals_on?' do
    context 'when approval queues are enabled locally' do
      before(:each) do
        subject.approvals_disabled = false
      end

      it 'returns true' do
        expect(subject.approvals_on?).to be_truthy
      end

      it 'ignores the global level status' do
        allow(subject).to receive_messages(:global_approvals_on? => false)
        expect(subject.approvals_on?).to be_truthy
      end
    end

    context 'when approval queues are disabled locally' do
      before(:each) do
        subject.approvals_disabled = true
      end

      it 'returns false' do
        expect(subject.approvals_on?).to be_falsey
      end

      it 'ignores the global level status' do
        allow(subject).to receive_messages(:global_approvals_on? => true)
        expect(subject.approvals_on?).to be_falsey
      end
    end
  end

  describe '.global_approvals_on?' do
    it 'checks the global approval status' do
      expect(ActsAsApprovable).to receive(:enabled?)
      subject.global_approvals_on?
    end
  end

  describe '.approvable_on?' do
    it { is_expected.to be_approvable_on(:create) }
    it { is_expected.to be_approvable_on(:update) }

    context 'when the model is approvable on :create events' do
      subject { CreatesApprovable }

      it { is_expected.to be_approvable_on(:create) }
      it { is_expected.not_to be_approvable_on(:update) }
    end

    context 'when the model is approvable on :update events' do
      subject { UpdatesApprovable }

      it { is_expected.to be_approvable_on(:update) }
      it { is_expected.not_to be_approvable_on(:create) }
    end
  end

  describe '.approvable_fields' do
    subject do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'nots'
      end
    end

    context 'with :only fields configured' do
      before(:each) do
        subject.acts_as_approvable :only => [:body, :extra]
      end

      it 'returns the configured fields' do
        expect(subject.approvable_fields).to eq(['body', 'extra'])
      end
    end

    context 'with :ignore fields configured' do
      before(:each) do
        subject.acts_as_approvable :ignore => [:title, :extra]
      end

      it 'returns the available fields minus whats ignored' do
        expect(subject.approvable_fields).to include('body')
      end

      it 'ignores timestamps' do
        expect(subject.approvable_fields).not_to include('created_at')
        expect(subject.approvable_fields).not_to include('updated_at')
      end

      it 'ignores primary keys' do
        expect(subject.approvable_fields).not_to include(subject.primary_key)
      end
    end
  end

  describe '.without_approval' do
    around(:each) do |example|
      subject.approvals_on
      example.run
      subject.approvals_on
    end

    it 'disables approval queues' do
      @record = subject.without_approval { |m| m.create(:title => 'title', :body => 'the body') }
      expect(@record.approval).not_to be
    end

    it 'enables the approval queue after running' do
      expect(subject).to be_approvals_on
      subject.without_approval { |m| m.create(:title => 'title', :body => 'the body') }
      expect(subject).to be_approvals_on
    end

    it 'returns the approval queue to the previous state' do
      subject.approvals_off
      subject.without_approval { |m| m.create(:title => 'title', :body => 'the body') }
      expect(subject).not_to be_approvals_on
    end
  end
end
