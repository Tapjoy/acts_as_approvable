require 'spec_helper'

describe ActsAsApprovable::Model do
  context 'when acts_as_approvable is not configured' do
    subject { NotApprovable }

    it { expect(subject.new).not_to have_many(:approvals) }

    it { is_expected.not_to extend(ActsAsApprovable::Model::ClassMethods) }
    it { is_expected.not_to extend(ActsAsApprovable::Model::InstanceMethods) }
    it { is_expected.not_to extend(ActsAsApprovable::Model::CreateInstanceMethods) }
    it { is_expected.not_to extend(ActsAsApprovable::Model::UpdateInstanceMethods) }
    it { is_expected.not_to extend(ActsAsApprovable::Model::DestroyInstanceMethods) }
  end

  context 'with default configuration options' do
    subject { DefaultApprovable }

    it { is_expected.to be_approvable_on(:create) }
    it { is_expected.to be_approvable_on(:update) }
    it { is_expected.to be_approvable_on(:destroy) }
    it { is_expected.to be_approvals_enabled }
    it { expect(subject.new).to have_many(:approvals) }

    it { is_expected.to extend(ActsAsApprovable::Model::ClassMethods) }
    it { is_expected.to extend(ActsAsApprovable::Model::InstanceMethods) }
    it { is_expected.to extend(ActsAsApprovable::Model::CreateInstanceMethods) }
    it { is_expected.to extend(ActsAsApprovable::Model::UpdateInstanceMethods) }
    it { is_expected.to extend(ActsAsApprovable::Model::DestroyInstanceMethods) }

    it 'has no approvable_field' do
      expect(subject.approvable_field).not_to be
    end

    it 'ignores timestamps' do
      expect(subject.approvable_ignore).to include('created_at')
      expect(subject.approvable_ignore).to include('updated_at')
    end

    it 'ignores the primary key' do
      expect(subject.approvable_ignore).to include(subject.primary_key)
    end
  end

  context 'with :create as the only event' do
    context 'and no other options' do
      subject { CreatesApprovable }

      it { is_expected.to be_approvable_on(:create) }
      it { is_expected.not_to be_approvable_on(:update) }
      it { is_expected.not_to be_approvable_on(:destroy) }

      it { is_expected.to extend(ActsAsApprovable::Model::ClassMethods) }
      it { is_expected.to extend(ActsAsApprovable::Model::InstanceMethods) }
      it { is_expected.to extend(ActsAsApprovable::Model::CreateInstanceMethods) }
      it { is_expected.not_to extend(ActsAsApprovable::Model::UpdateInstanceMethods) }
      it { is_expected.not_to extend(ActsAsApprovable::Model::DestroyInstanceMethods) }
    end

    context 'and a :state_field' do
      subject { CreatesWithStateApprovable }

      it 'has an approvable_field' do
        expect(subject.approvable_field).to be
      end

      it 'ignores the approvable_field' do
        expect(subject.approvable_ignore).to include(subject.approvable_field.to_s)
      end

      it 'ignores timestamps' do
        expect(subject.approvable_ignore).to include('created_at')
        expect(subject.approvable_ignore).to include('updated_at')
      end

      it 'ignores the primary key' do
        expect(subject.approvable_ignore).to include(subject.primary_key)
      end
    end
  end

  context 'with :update as the only event' do
    context 'and no other options' do
      subject { UpdatesApprovable }

      it { is_expected.to be_approvable_on(:update) }
      it { is_expected.not_to be_approvable_on(:create) }
      it { is_expected.not_to be_approvable_on(:destroy) }

      it { is_expected.to extend(ActsAsApprovable::Model::ClassMethods) }
      it { is_expected.to extend(ActsAsApprovable::Model::InstanceMethods) }
      it { is_expected.to extend(ActsAsApprovable::Model::UpdateInstanceMethods) }
      it { is_expected.not_to extend(ActsAsApprovable::Model::CreateInstanceMethods) }
      it { is_expected.not_to extend(ActsAsApprovable::Model::DestroyInstanceMethods) }
    end
  end

  context 'with :destroy as the only event' do
    context 'and no other options' do
      subject { DestroysApprovable }

      it { is_expected.to be_approvable_on(:destroy) }
      it { is_expected.not_to be_approvable_on(:create) }
      it { is_expected.not_to be_approvable_on(:update) }

      it { is_expected.to extend(ActsAsApprovable::Model::ClassMethods) }
      it { is_expected.to extend(ActsAsApprovable::Model::InstanceMethods) }
      it { is_expected.to extend(ActsAsApprovable::Model::DestroyInstanceMethods) }
      it { is_expected.not_to extend(ActsAsApprovable::Model::CreateInstanceMethods) }
      it { is_expected.not_to extend(ActsAsApprovable::Model::UpdateInstanceMethods) }
    end
  end
end
